const std = @import("std");
const builtin = @import("builtin");

const Message = @import("msg").Message;
const sock = if (builtin.os.tag == .emscripten)
    @import("wasm.zig")
else
    @import("native.zig");

pub const MessageCallback = *const fn (msg: Message) void;
var on_message: ?MessageCallback = null;

fn onMessage(msg: []const u8) void {
    if (on_message) |cb| {
        var fbs = std.io.fixedBufferStream(msg);
        const decoded = Message.decode(fbs.reader()) catch {
            std.debug.print("failed to decode message", .{});
            return;
        };

        cb(decoded);
    }
}

pub fn setMessageCallback(cb: MessageCallback) void {
    on_message = cb;

    sock.setMessageCallback(onMessage);
}

pub fn init(address: [*c]const u8, port: c_int, url: []const u8) void {
    if (builtin.os.tag == .emscripten) {
        sock.init(url);
    } else {
        sock.init(address, port);
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
