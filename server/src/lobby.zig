const std = @import("std");
const Message = @import("msg").Message;

const Client = @import("client.zig").Client;
const Player = @import("player.zig").Player;

const LobbyId = u32;
const PlayerId = u32;

pub var lobby_manager: LobbyManager = undefined;

pub fn initLobbyManager(allocator: std.mem.Allocator) void {
    lobby_manager = LobbyManager.init(allocator);
}

pub fn deinitLobbyManager() void {
    lobby_manager.lobbies.deinit();
}

const LobbyPlayer = struct {
    player: *Player,
    client: *Client,

    pub fn init(player: *Player, client: *Client) LobbyPlayer {
        return .{
            .player = player,
            .client = client,
        };
    }
};

pub const Lobby = struct {
    id: LobbyId,
    players: std.AutoHashMap(PlayerId, LobbyPlayer),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, id: LobbyId) Lobby {
        return .{
            .id = id,
            .players = std.AutoHashMap(PlayerId, LobbyPlayer).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn broadcast(self: *Lobby, msg: Message) !void {
        var buf: [1024]u8 = undefined;
        const fbs = std.io.fixedBufferStream(&buf);
        try msg.encode(fbs.writer());

        var it = self.players.iterator();
        while (it.next()) |entry| {
            const client = entry.value_ptr.*;
            try client.send(msg);
        }
    }

    pub fn deinit(self: *Lobby) void {
        self.players.deinit();
    }
};

pub const LobbyManager = struct {
    lock: std.Thread.Mutex = .{},
    lobbies: std.AutoHashMap(LobbyId, *Lobby),
    allocator: std.mem.Allocator,

    next_id: LobbyId = 1,

    pub fn init(allocator: std.mem.Allocator) LobbyManager {
        return .{
            .lobbies = std.AutoHashMap(LobbyId, *Lobby).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn createLobby(self: *LobbyManager) !*Lobby {
        const id = self.next_id;
        self.next_id += 1;

        const lobby = try self.allocator.create(Lobby);
        lobby.* = Lobby.init(self.allocator, id);

        try self.lobbies.put(id, lobby);
        return lobby;
    }

    pub fn get(self: *LobbyManager, id: LobbyId) ?*Lobby {
        return self.lobbies.get(id);
    }
};
