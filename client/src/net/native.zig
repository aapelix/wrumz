const std = @import("std");
const c = @import("../c.zig").c;

const MAX_QUEUE = 8;
const MSG_SIZE = 256;

var send_queue: [MAX_QUEUE][c.LWS_PRE + MSG_SIZE]u8 = undefined;
var send_lens: [MAX_QUEUE]usize = undefined;
var queue_head: usize = 0;
var queue_tail: usize = 0;

pub fn queueMessage(msg: []const u8) void {
    const next = (queue_tail + 1) % MAX_QUEUE;
    if (next == queue_head) return;

    const slot = &send_queue[queue_tail];
    const len = @min(msg.len, MSG_SIZE);
    @memcpy(slot[c.LWS_PRE..][0..len], msg[0..len]);
    send_lens[queue_tail] = len;
    queue_tail = next;

    if (ws_wsi) |wsi| {
        _ = c.lws_callback_on_writable(wsi);
    }
}

pub const MessageCallback = *const fn (msg: []const u8) void;
var on_message: ?MessageCallback = null;

pub fn setMessageCallback(cb: MessageCallback) void {
    on_message = cb;
}

var ws_context: ?*c.lws_context = null;
var ws_wsi: ?*c.lws = null;

const protocols = [_]c.lws_protocols{
    .{
        .name = "wrum",
        .callback = wsCallback,
        .per_session_data_size = 0,
        .rx_buffer_size = 4096,
    },
    .{ .name = null, .callback = null, .per_session_data_size = 0, .rx_buffer_size = 0 },
};

pub fn init(address: [*c]const u8, port: c_int) void {
    var info: c.lws_context_creation_info = std.mem.zeroes(c.lws_context_creation_info);
    info.port = c.CONTEXT_PORT_NO_LISTEN;
    info.protocols = &protocols;

    ws_context = c.lws_create_context(&info);

    var client: c.lws_client_connect_info = std.mem.zeroes(c.lws_client_connect_info);
    client.context = ws_context;
    client.address = address;
    client.port = port;
    client.path = "/ws";
    client.host = client.address;
    client.origin = client.address;
    client.protocol = protocols[0].name;

    ws_wsi = c.lws_client_connect_via_info(&client);
}

pub fn poll() void {
    if (ws_context) |ctx| {
        _ = c.lws_service(ctx, -1);
    }
}

pub fn wsCallback(
    wsi: ?*c.lws,
    reason: c.lws_callback_reasons,
    user: ?*anyopaque,
    in: ?*anyopaque,
    len: usize,
) callconv(.c) c_int {
    _ = user;

    switch (reason) {
        c.LWS_CALLBACK_CLIENT_ESTABLISHED => {
            std.debug.print("WS connected\n", .{});
            ws_wsi = wsi;
        },

        c.LWS_CALLBACK_CLIENT_RECEIVE => {
            const msg = @as([*]u8, @ptrCast(in))[0..len];
            if (on_message) |cb| cb(msg);
        },

        c.LWS_CALLBACK_CLIENT_WRITEABLE => {
            if (queue_head != queue_tail) {
                const slot = &send_queue[queue_head];
                const l = send_lens[queue_head];
                _ = c.lws_write(wsi, slot[c.LWS_PRE..].ptr, l, c.LWS_WRITE_TEXT);
                queue_head = (queue_head + 1) % MAX_QUEUE;

                if (queue_head != queue_tail) {
                    _ = c.lws_callback_on_writable(wsi);
                }
            }
        },

        c.LWS_CALLBACK_CLIENT_CONNECTION_ERROR => {
            std.debug.print("WS connection failed\n", .{});
        },

        else => {},
    }

    return 0;
}
