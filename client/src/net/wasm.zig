const std = @import("std");
const c = @cImport({
    if (@import("builtin").os.tag == .emscripten) {
        @cInclude("emscripten/websocket.h");
    }
});

pub const MessageCallback = *const fn (msg: []const u8) void;
var on_message: ?MessageCallback = null;

pub fn setMessageCallback(cb: MessageCallback) void {
    on_message = cb;
}

fn onOpen(
    event_type: c_int,
    _: [*c]const c.EmscriptenWebSocketOpenEvent,
    user_data: ?*anyopaque,
) callconv(.c) c.EM_BOOL {
    _ = event_type;
    _ = user_data;

    return true;
}

fn onMessage(
    event_type: c_int,
    event: [*c]const c.EmscriptenWebSocketMessageEvent,
    user_data: ?*anyopaque,
) callconv(.c) c.EM_BOOL {
    _ = event_type;
    _ = user_data;

    const data = event.*.data[0..event.*.numBytes];
    if (on_message) |cb| {
        cb(data);
    }

    return true;
}

var socket_handle: c.EMSCRIPTEN_WEBSOCKET_T = 0;

pub fn send(data: []const u8) !void {
    _ = c.emscripten_websocket_send_binary(
        socket_handle,
        @ptrCast(@constCast(data.ptr)),
        data.len,
    );
}

pub fn init(url: [:0]const u8) void {
    var attrs: c.EmscriptenWebSocketCreateAttributes = undefined;

    attrs = std.mem.zeroes(c.EmscriptenWebSocketCreateAttributes);
    attrs.url = url.ptr;
    attrs.protocols = null;
    attrs.createOnMainThread = true;

    socket_handle = c.emscripten_websocket_new(&attrs);

    std.debug.assert(socket_handle > 0);

    _ = c.emscripten_websocket_set_onopen_callback(
        socket_handle,
        null,
        onOpen,
    );
    _ = c.emscripten_websocket_set_onmessage_callback(
        socket_handle,
        null,
        onMessage,
    );
}
