const std = @import("std");
const httpz = @import("httpz");
const websocket = httpz.websocket;

const Message = @import("msg").Message;

const Client = @import("client.zig").Client;
const lobby = @import("lobby.zig");
const loop = @import("loop.zig");

const Allocator = std.mem.Allocator;
const PORT = 23901;

pub const std_options = std.Options{ .log_scope_levels = &[_]std.log.ScopeLevel{
    .{ .scope = .websocket, .level = .err },
} };

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    defer _ = gpa.deinit();

    lobby.initLobbyManager(allocator);
    defer lobby.deinitLobbyManager();

    const sim_thread = try std.Thread.spawn(.{}, loop.loop, .{allocator});
    sim_thread.detach();
    defer sim_thread.join();

    var server = try httpz.Server(Handler).init(allocator, .{ .address = .all(23901) }, Handler{});
    defer server.deinit();
    defer server.stop();

    var router = try server.router(.{});

    router.get("/ws", ws, .{});

    std.debug.print("running on {d}\n", .{PORT});
    try server.listen();
}

const Handler = struct {
    pub const WebsocketHandler = Client;
};

fn ws(_: Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const ctx = Client.Context{ .user_id = 1 };

    if (try httpz.upgradeWebsocket(Client, req, res, &ctx) == false) {
        res.status = 400;
        res.body = "not a websocket request";
    }
}
