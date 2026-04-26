const std = @import("std");
const msg = @import("msg");

const lobby = @import("lobby.zig");

pub fn loop(allocator: std.mem.Allocator) !void {
    while (true) {
        std.Thread.sleep(16 * std.time.ns_per_ms);

        lobby.lobby_manager.lock.lock();
        defer lobby.lobby_manager.lock.unlock();

        var it = lobby.lobby_manager.lobbies.iterator();
        while (it.next()) |entry| {
            const l = entry.value_ptr.*;

            if (l.players.count() == 0) {
                std.debug.print("Deinitializing lobby {}\n", .{l.id});
                l.deinit();
                _ = lobby.lobby_manager.lobbies.remove(l.id);
            }

            // update game state here

            var update_players: std.ArrayList(*msg.ServerPlayer) = try .initCapacity(allocator, l.players.count());
            var it2 = l.players.iterator();
            while (it2.next()) |e| {
                const p = e.value_ptr.*;
                try update_players.append(allocator, .{ .x = p.player.x, .y = p.player.y, .rotation = p.player.rotation, .id = e.key });
            }

            const update_msg = msg.Message{
                .serverLobbyUpdate = .{ .players = update_players.toSlice() },
            };

            try l.broadcast(update_msg);
        }
    }
}
