const std = @import("std");
const msg = @import("msg");

const lobby = @import("lobby.zig");

pub fn loop(allocator: std.mem.Allocator) !void {
    var last = std.time.milliTimestamp();

    while (true) {
        std.Thread.sleep(16 * std.time.ns_per_ms);

        const now = std.time.milliTimestamp();
        const dt_ms = now - last;
        last = now;

        const dt: f32 = @as(f32, @floatFromInt(dt_ms)) / 1000.0;

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

            var update_it = l.players.iterator();
            while (update_it.next()) |e| {
                const p = e.value_ptr.*;

                p.player.update(dt);
            }

            var update_players: std.ArrayList(msg.ServerPlayer) = try .initCapacity(allocator, l.players.count());
            var it2 = l.players.iterator();
            while (it2.next()) |e| {
                const p = e.value_ptr.*;
                try update_players.append(allocator, msg.ServerPlayer{ .x = p.player.x, .y = p.player.y, .rotation = p.player.rotation, .id = e.key_ptr.* });
            }

            const update_msg = msg.Message{
                .serverLobbyUpdate = .{ .players = try update_players.toOwnedSlice(allocator) },
            };

            try l.broadcast(update_msg);
        }
    }
}
