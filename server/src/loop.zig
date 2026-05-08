const std = @import("std");
const msg = @import("msg");

const lobby = @import("lobby.zig");

pub fn loop(allocator: std.mem.Allocator) !void {
    const tick_rate = 60;
    const tick_ns = std.time.ns_per_s / tick_rate;

    var send_message: i8 = 3;

    while (true) {
        send_message = send_message - 1;

        const send = send_message == 0;
        if (send) {
            send_message = 3;
        }

        const start = std.time.nanoTimestamp();
        const dt: f32 = 1.0 / 60.0;

        lobby.lobby_manager.lock.lock();
        defer lobby.lobby_manager.lock.unlock();

        var it = lobby.lobby_manager.lobbies.iterator();
        while (it.next()) |entry| {
            const l = entry.value_ptr.*;

            if (l.players.count() == 0) {
                std.debug.print("Deinitializing lobby {}\n", .{l.id});
                l.deinit();
                _ = lobby.lobby_manager.lobbies.remove(l.id);
                continue;
            }

            std.debug.assert(l.players.count() > 0);

            var update_it = l.players.iterator();
            while (update_it.next()) |e| {
                const p = e.value_ptr;

                p.player.update(dt);
            }

            var update_players: std.ArrayList(msg.ServerPlayer) = try .initCapacity(allocator, l.players.count());
            defer update_players.deinit(allocator);

            var it2 = l.players.iterator();
            while (it2.next()) |e| {
                const p = e.value_ptr.*;
                try update_players.append(allocator, msg.ServerPlayer{ .x = p.player.x, .y = p.player.y, .rotation = p.player.rotation, .id = e.key_ptr.* });
            }

            const update_msg = msg.Message{
                .serverLobbyUpdate = .{ .players = try update_players.toOwnedSlice(allocator) },
            };

            if (send) try l.broadcast(update_msg);
        }

        const elapsed = std.time.nanoTimestamp() - start;
        if (elapsed < tick_ns) {
            std.Thread.sleep(@intCast(tick_ns - elapsed));
        }
    }
}
