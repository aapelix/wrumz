const std = @import("std");
const httpz = @import("httpz");

const websocket = httpz.websocket;

const Message = @import("msg").Message;

const Allocator = std.mem.Allocator;
const PORT = 23901;

pub const std_options = std.Options{ .log_scope_levels = &[_]std.log.ScopeLevel{
    .{ .scope = .websocket, .level = .err },
} };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var server = try httpz.Server(Handler).init(allocator, .{ .address = .localhost(PORT) }, Handler{});
    defer server.deinit();
    defer server.stop();

    var router = try server.router(.{});

    router.get("/ws", ws, .{});

    std.debug.print("running on localhost:{d}\n", .{PORT});
    try server.listen();
}

const Handler = struct {
    pub const WebsocketHandler = Client;
};

const Client = struct {
    user_id: u32,
    conn: *websocket.Conn,

    const Context = struct {
        user_id: u32,
    };

    pub fn init(conn: *websocket.Conn, ctx: *const Context) !Client {
        return .{
            .conn = conn,
            .user_id = ctx.user_id,
        };
    }

    pub fn afterInit(self: *Client) !void {
        _ = self;
    }

    pub fn clientMessage(self: *Client, data: []const u8) !void {
        var fbs = std.io.fixedBufferStream(data);
        const decoded = Message.decode(fbs.reader()) catch {
            std.debug.print("failed to decode message", .{});
            return;
        };
        switch (decoded) {
            .ping => |p| {
                std.debug.print("got ping from: {s}\n", .{p.username});
            },
        }
        return self.conn.write(data);
    }

    pub fn send(self: *Client, msg: Message) !void {
        var buf: [1024]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buf);

        try msg.encode(fbs.writer());

        const written = fbs.pos;
        const bytes = buf[0..written];

        return self.conn.write(bytes);
    }
};

fn ws(_: Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const ctx = Client.Context{ .user_id = 1 };

    if (try httpz.upgradeWebsocket(Client, req, res, &ctx) == false) {
        res.status = 400;
        res.body = "not a websocket request";
    }
}
