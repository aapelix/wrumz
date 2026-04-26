const std = @import("std");
const Message = @import("msg").Message;
const websocket = @import("httpz").websocket;

const lobby = @import("lobby.zig");
const Player = @import("player.zig").Player;

pub const Client = struct {
    user_id: u32,
    conn: *websocket.Conn,
    lobby: ?*lobby.Lobby = null,

    pub const Context = struct {
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
        const decoded = Message.decode(std.heap.page_allocator, fbs.reader()) catch return;

        switch (decoded) {
            .clientCreateLobby => {
                if (self.lobby != null) return;

                lobby.lobby_manager.lock.lock();
                defer lobby.lobby_manager.lock.unlock();

                const l = try lobby.lobby_manager.createLobby();
                self.lobby = l;

                const id = self.user_id;
                var p = Player{ .x = 0, .y = 0, .rotation = 0 };
                try l.players.put(id, .init(&p, self));
            },
            .clientJoinLobby => |msg| {
                if (self.lobby != null) return;

                lobby.lobby_manager.lock.lock();
                defer lobby.lobby_manager.lock.unlock();

                const l = lobby.lobby_manager.get(msg.id) orelse return;
                self.lobby = l;

                var p = Player{ .x = 0, .y = 0, .rotation = 0 };
                try l.players.put(self.user_id, .init(&p, self));
            },
            .clientInput => |input| {
                if (self.lobby == null) return;

                lobby.lobby_manager.lock.lock();
                defer lobby.lobby_manager.lock.unlock();

                const l = self.lobby.?;
                const player = l.players.get(self.user_id) orelse return;
                player.player.throttle = input.throttle;
                player.player.steering = input.steering;
                std.debug.print("Received input from user {}: throttle {}, steering {}\n", .{ self.user_id, input.throttle, input.steering });
            },
            else => {},
        }
    }

    pub fn send(self: *Client, msg: Message) !void {
        var buf: [1024]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buf);

        try msg.encode(fbs.writer());

        const written = fbs.pos;
        const bytes = buf[0..written];

        return self.conn.write(bytes);
    }

    pub fn close(self: *Client) void {
        std.debug.print("Closing connection for user {}\n", .{self.user_id});

        if (self.lobby) |l| {
            lobby.lobby_manager.lock.lock();
            defer lobby.lobby_manager.lock.unlock();

            _ = l.players.remove(self.user_id);
        }
    }
};
