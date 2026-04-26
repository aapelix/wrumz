const std = @import("std");

const stack = @import("../stack.zig");
const c = @import("../c.zig").c;

pub const Car = struct {
    pos: [2]f32,
    rotation: f32,

    body: stack.Stack,
    //tires: [4]stack.Stack,

    pub fn init(allocator: std.mem.Allocator, renderer: *c.SDL_Renderer, pos: [2]f32, rotation: f32) !Car {
        const body = try stack.Stack.init(allocator, renderer, "assets/cars", 7);
        //const tires = try stack.Stack.init(allocator, renderer, "assets/car/tires", 4);

        return Car{
            .pos = pos,
            .rotation = rotation,
            .body = body,
            //.tires = tires,
        };
    }

    pub fn draw(self: *const Car, renderer: *c.SDL_Renderer) void {
        self.body.draw(renderer, self.pos, self.rotation);
        //self.tires.draw(renderer, [self.x, self.y], self.rotation);
    }

    pub fn deinit(self: *Car, allocator: std.mem.Allocator) void {
        self.body.deinit(allocator);
        //self.tires.deinit(allocator);
    }
};
