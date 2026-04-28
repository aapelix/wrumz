const std = @import("std");
const Message = @import("msg").Message;

const Car = @import("../entity/car.zig").Car;
const c = @import("../c.zig").c;
const socket = @import("../net/socket.zig");
const camera_mod = @import("../camera.zig");

pub const GameScene = struct {
    camera: camera_mod.Camera,
    cars: std.AutoHashMap(u32, Car),

    last_throttle: i8,
    last_steering: i8,

    target_x: f32,
    target_y: f32,
    target_rotation: f32,

    user_id: u32,

    pub fn init(allocator: std.mem.Allocator) !GameScene {
        const cars: std.AutoHashMap(u32, Car) = .init(allocator);

        return GameScene{
            .camera = camera_mod.Camera.init(),
            .cars = cars,
            .last_throttle = 0,
            .last_steering = 0,
            .target_x = 0,
            .target_y = 0,
            .target_rotation = 0,
            .user_id = 0,
        };
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

        self.camera.update(self.target_x, self.target_y, self.target_rotation);
    }

    pub fn handleMsg(self: *GameScene, allocator: std.mem.Allocator, renderer: *c.SDL_Renderer, msg: Message) !void {
        switch (msg) {
            .serverLobbyJoined => |joined| {
                self.user_id = joined.id;
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
                            car.pos = [_]f32{ player.x, player.y };
                            car.rotation = player.rotation;
                            found = true;

                            if (id == self.user_id) {
                                self.target_x = player.x;
                                self.target_y = player.y;
                                self.target_rotation = player.rotation;
                            }
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
        var it = self.cars.iterator();
        while (it.next()) |entry| {
            const car = entry.value_ptr.*;
            car.draw(renderer, self.camera);
        }
    }

    pub fn deinit(self: *GameScene, allocator: std.mem.Allocator) void {
        var it = self.cars.iterator();
        while (it.next()) |entry| {
            const car = entry.value_ptr;
            car.deinit(allocator);
        }
        self.cars.deinit();
    }
};
