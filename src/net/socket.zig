const builtin = @import("builtin");
const sock = if (builtin.os.tag == .emscripten)
    @import("wasm.zig")
else
    @import("native.zig");

pub const MessageCallback = *const fn (msg: []const u8) void;
var on_message: ?MessageCallback = null;

pub fn setMessageCallback(cb: MessageCallback) void {
    on_message = cb;

    sock.setMessageCallback(cb);
}

pub fn init(address: [*c]const u8, port: c_int, url: []const u8) void {
    if (builtin.os.tag == .emscripten) {
        sock.init(url);
    } else {
        sock.init(address, port);
    }
}

pub fn send(data: []const u8) !void {
    if (builtin.os.tag == .emscripten) {
        try sock.send(data);
    } else {
        sock.queueMessage(data);
    }
}

pub fn poll() void {
    if (builtin.os.tag != .emscripten) {
        sock.poll();
    }
}
