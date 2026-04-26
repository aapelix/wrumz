const std = @import("std");
const builtin = @import("builtin");

const Message = @import("msg").Message;
const sock = if (builtin.os.tag == .emscripten)
    @import("wasm.zig")
else
    @import("native.zig");

pub const MessageCallback = *const fn (msg: Message) void;
var on_message: ?MessageCallback = null;

const allocator = if (builtin.os.tag == .emscripten)
    std.heap.c_allocator
else
    std.heap.page_allocator;

fn onMessage(msg: []const u8) void {
    if (on_message) |cb| {
        var fbs = std.io.fixedBufferStream(msg);
        const decoded = Message.decode(allocator, fbs.reader()) catch |err| {
            std.debug.print("failed to decode message: {any}\n", .{err});
            return;
        };

        cb(decoded);
    }
}

pub fn setMessageCallback(cb: MessageCallback) void {
    on_message = cb;
    std.debug.print("setting message callback {any}\n", .{cb});

    sock.setMessageCallback(onMessage);
}

pub fn init(address: [:0]const u8, port: c_int, path: [:0]const u8, protocol: [:0]const u8) !void {
    if (builtin.os.tag == .emscripten) {
        var buf: [1024]u8 = undefined;
        const url = try std.fmt.bufPrintZ(
            &buf,
            "{s}://{s}:{d}{s}",
            .{ protocol, address, port, path },
        );
        sock.init(url);
    } else {
        sock.init(@ptrCast(address), port, @ptrCast(path));
    }
}

pub fn send(data: Message) !void {
    var buf: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);

    try data.encode(fbs.writer());

    const written = fbs.pos;
    const bytes = buf[0..written];

    if (builtin.os.tag == .emscripten) {
        try sock.send(bytes);
    } else {
        sock.queueMessage(bytes);
    }
}

pub fn poll() void {
    if (builtin.os.tag != .emscripten) {
        sock.poll();
    }
}
