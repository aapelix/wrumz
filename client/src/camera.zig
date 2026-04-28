const c = @import("c.zig").c;
const std = @import("std");

pub const Camera = struct {
    x: f32,
    y: f32,
    rotation: f32,
    smooth: f32,

    pub fn init() Camera {
        return Camera{
            .x = 0,
            .y = 0,
            .rotation = 0,
            .smooth = 0.05,
        };
    }

    pub fn update(self: *Camera, target_x: f32, target_y: f32, target_rotation: f32) void {
        self.x += (target_x - self.x) * self.smooth;
        self.y += (target_y - self.y) * self.smooth;

        const rot_diff = @mod(target_rotation - self.rotation + 180.0, 360.0) - 180.0;
        self.rotation += rot_diff * self.smooth;
    }

    pub fn apply(self: *const Camera, target: *[2]f32, rotation: *f32) void {
        const translated_x = target[0] - self.x;
        const translated_y = target[1] - self.y;

        const rad = -self.rotation * std.math.pi / 180;
        const cos = std.math.cos(rad);
        const sin = std.math.sin(rad);

        const rotated_x = translated_x * cos - translated_y * sin;
        const rotated_y = translated_x * sin + translated_y * cos;

        target[0] = rotated_x + 160;
        target[1] = rotated_y + 120;
        rotation.* = @floor(rotation.* - self.rotation);
    }
};
