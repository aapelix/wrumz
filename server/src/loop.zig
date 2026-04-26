const std = @import("std");

const lobby = @import("lobby.zig");

pub fn loop() void {
    while (true) {
        std.Thread.sleep(16 * std.time.ns_per_ms);

        lobby.lobby_manager.lock.lock();
        defer lobby.lobby_manager.lock.unlock();

        var it = lobby.lobby_manager.lobbies.iterator();
        while (it.next()) |entry| {
            const l = entry.value_ptr.*;
            std.debug.print("Lobby {} has {} players\n", .{ l.id, l.players.count() });

            if (l.players.count() == 0) {
                std.debug.print("Deinitializing lobby {}\n", .{l.id});
                l.deinit();
                _ = lobby.lobby_manager.lobbies.remove(l.id);
            }
        }
    }
}
