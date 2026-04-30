const std = @import("std");
const Message = @import("msg").Message;

const Car = @import("../entity/car.zig").Car;
const c = @import("../c.zig").c;
const socket = @import("../net/socket.zig");
const camera_mod = @import("../camera.zig");
const ui = @import("../ui/ui.zig");
const map_mod = @import("../map/load.zig");

pub const GameScene = struct {
    camera: camera_mod.Camera,
    cars: std.AutoHashMap(u32, Car),
    map: ?map_mod.Map,

    last_throttle: i8,
    last_steering: i8,

    target_x: f32,
    target_y: f32,
    target_rotation: f32,

    user_id: u32,
    lobby_code_label: ui.Label,

    pub fn init(allocator: std.mem.Allocator) !GameScene {
        const cars: std.AutoHashMap(u32, Car) = .init(allocator);

        return GameScene{ .camera = camera_mod.Camera.init(), .cars = cars, .map = null, .last_throttle = 0, .last_steering = 0, .target_x = 0, .target_y = 0, .target_rotation = 0, .user_id = 0, .lobby_code_label = ui.Label.init(.{ .text = "", .x = 10, .y = 10 }) };
    }

    pub fn update(self: *GameScene, dt: f32) !void {
        _ = dt;

        const state = c.SDL_GetKeyboardState(null);
        const throttle: i8 = if (state[c.SDL_SCANCODE_W]) 1 else if (state[c.SDL_SCANCODE_S]) -1 else 0;
        const steering: i8 = if (state[c.SDL_SCANCODE_A]) -1 else if (state[c.SDL_SCANCODE_D]) 1 else 0;

        if (throttle != self.last_throttle or steering != self.last_steering) {
            self.last_throttle = throttle;
            self.last_steering = steering;

            const msg = Message{ .clientInput = .{ .throttle = throttle, .steering = steering } };
            try socket.send(msg);
        }

        var it = self.cars.iterator();
        while (it.next()) |entry| {
            const car = entry.value_ptr;
            const id = entry.key_ptr.*;

            car.update();

            if (id == self.user_id) {
                self.target_x = car.target_pos[0];
                self.target_y = car.target_pos[1];
                self.target_rotation = car.target_rotation;
            }
        }
        self.camera.update(self.target_x, self.target_y, self.target_rotation);
    }

    pub fn handleMsg(self: *GameScene, allocator: std.mem.Allocator, renderer: *c.SDL_Renderer, msg: Message) !void {
        switch (msg) {
            .serverLobbyJoined => |joined| {
                self.user_id = joined.id;
                const code = try std.fmt.allocPrint(allocator, "{}", .{joined.code});
                defer allocator.free(code);
                self.lobby_code_label.setText(code);

                if (self.map == null) {
                    self.map = try map_mod.Map.load(allocator, renderer, "assets/maps/test.tmj");
                }
            },
            .serverLobbyUpdate => |state| {
                for (state.players) |player| {
                    if (!self.cars.contains(player.id)) {
                        const new_car = try Car.init(allocator, renderer, [_]f32{ player.x, player.y }, player.rotation);
                        _ = try self.cars.put(player.id, new_car);
                    }
                }

                var it = self.cars.iterator();
                while (it.next()) |entry| {
                    const id = entry.key_ptr.*;
                    var car = entry.value_ptr;

                    var found = false;
                    for (state.players) |player| {
                        if (player.id == id) {
                            car.target_pos = [_]f32{ player.x, player.y };
                            car.target_rotation = player.rotation;
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        var delete_car = entry.value_ptr;
                        delete_car.deinit(allocator);
                        _ = self.cars.remove(id);
                    }
                }
            },
            else => {},
        }
    }

    pub fn draw(self: *GameScene, renderer: *c.SDL_Renderer) void {
        if (self.map) |*m| {
            m.draw(renderer, self.camera);
        }

        var it = self.cars.iterator();
        while (it.next()) |entry| {
            const car = entry.value_ptr.*;
            car.draw(renderer, self.camera);
        }

        self.lobby_code_label.draw(renderer, ui.default_theme);
    }

    pub fn deinit(self: *GameScene, allocator: std.mem.Allocator) void {
        var it = self.cars.iterator();
        while (it.next()) |entry| {
            const car = entry.value_ptr;
            car.deinit(allocator);
        }
        self.cars.deinit();
        if (self.map) |*m| {
            m.deinit(allocator);
        }
    }
};
