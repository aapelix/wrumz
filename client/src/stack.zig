const std = @import("std");
const sdl = @import("c.zig").c;
const assets = @import("assets/load.zig");
const camera_mod = @import("camera.zig");

pub const Stack = struct {
    textures: std.ArrayList(*sdl.SDL_Texture),

    pub fn init(allocator: std.mem.Allocator, renderer: *sdl.SDL_Renderer, path: []const u8, count: usize) !Stack {
        const textures = try assets.loadFolder(allocator, renderer, path, count);
        return Stack{
            .textures = textures,
        };
    }

    pub fn draw(self: *const Stack, renderer: *sdl.SDL_Renderer, pos: [2]f32, rotation: f32, camera: camera_mod.Camera) void {
        for (self.textures.items, 0..) |tex, i| {
            var dst_pos = pos;
            var dst_rotation = rotation;
            camera.apply(&dst_pos, &dst_rotation);

            const dst = sdl.SDL_FRect{
                .x = dst_pos[0],
                .y = dst_pos[1] - @as(f32, @floatFromInt(i)),
                .w = @as(f32, @floatFromInt(tex.w)),
                .h = @as(f32, @floatFromInt(tex.h)),
            };

            _ = sdl.SDL_RenderTextureRotated(renderer, tex, null, &dst, dst_rotation, null, sdl.SDL_FLIP_NONE);
        }
    }

    pub fn deinit(self: *Stack, allocator: std.mem.Allocator) void {
        for (self.textures.items) |texture| {
            sdl.SDL_DestroyTexture(texture);
        }
        self.textures.deinit(allocator);
    }
};
