const std = @import("std");

const stack = @import("../stack.zig");
const c = @import("../c.zig").c;
const camera_mod = @import("../camera.zig");

pub const Car = struct {
    pos: [2]f32,
    target_pos: [2]f32,
    rotation: f32,
    target_rotation: f32,

    body: stack.Stack,
    //tires: [4]stack.Stack,

    pub fn init(allocator: std.mem.Allocator, renderer: *c.SDL_Renderer, pos: [2]f32, rotation: f32) !Car {
        const body = try stack.Stack.init(allocator, renderer, "assets/cars", 7);
        //const tires = try stack.Stack.init(allocator, renderer, "assets/car/tires", 4);

        return Car{
            .pos = pos,
            .target_pos = pos,
            .rotation = rotation,
            .target_rotation = rotation,
            .body = body,
            //.tires = tires,
        };
    }

    pub fn update(self: *Car) void {
        self.pos[0] += (self.target_pos[0] - self.pos[0]) * 0.2;
        self.pos[1] += (self.target_pos[1] - self.pos[1]) * 0.2;

        const rot_diff = @mod(self.target_rotation - self.rotation + 180.0, 360.0) - 180.0;
        self.rotation += rot_diff * 0.2;
    }

    pub fn draw(self: *const Car, renderer: *c.SDL_Renderer, camera: camera_mod.Camera) void {
        self.body.draw(renderer, self.pos, self.rotation, camera);
        //self.tires.draw(renderer, [self.x, self.y], self.rotation);
    }

    pub fn deinit(self: *Car, allocator: std.mem.Allocator) void {
        self.body.deinit(allocator);
        //self.tires.deinit(allocator);
    }
};
