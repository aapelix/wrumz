const std = @import("std");
const c = @import("../c.zig").c;

pub const Tile = struct {
    x: u32,
    y: u32,
    texture_i: u32,

    pub fn draw(self: *Tile, r: *c.SDL_Renderer, tiles_per_row: u32, tilewidth: u32, tileheight: u32, tileset: *c.SDL_Texture) void {
        const tx = self.texture_i % tiles_per_row;
        const ty = self.texture_i / tiles_per_row;

        const src_x = tx * tilewidth;
        const src_y = ty * tileheight;

        const src = c.SDL_FRect{
            .x = @floatFromInt(src_x),
            .y = @floatFromInt(src_y),
            .w = @floatFromInt(tilewidth),
            .h = @floatFromInt(tileheight),
        };

        const dst = c.SDL_FRect{
            .x = @floatFromInt(self.x * tilewidth),
            .y = @floatFromInt(self.y * tileheight),
            .w = @floatFromInt(tilewidth),
            .h = @floatFromInt(tileheight),
        };
        _ = c.SDL_RenderTexture(r, tileset, &src, &dst);
    }
};
