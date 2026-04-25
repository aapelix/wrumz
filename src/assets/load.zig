const std = @import("std");
const c = @import("../c.zig").c;

pub fn load(renderer: *c.SDL_Renderer, path: [*:0]const u8) *c.SDL_Texture {
    const image = c.SDL_LoadPNG(path);
    if (image == null) {
        @panic("failed to load image");
    }

    defer c.SDL_DestroySurface(image);

    const texture = c.SDL_CreateTextureFromSurface(renderer, image);
    _ = c.SDL_SetTextureScaleMode(texture, c.SDL_SCALEMODE_NEAREST);

    return texture;
}

pub fn loadFolder(allocator: std.mem.Allocator, renderer: *c.SDL_Renderer, path: []const u8, count: usize) !std.ArrayList(*c.SDL_Texture) {
    var textures: std.ArrayList(*c.SDL_Texture) = try .initCapacity(allocator, count + 1);

    for (0..count) |i| {
        var buf: [256]u8 = undefined;
        const file_path = try std.fmt.bufPrintZ(&buf, "{s}/img_{d}.png", .{ path, i + 1 });

        const texture = load(renderer, file_path);
        _ = c.SDL_SetTextureScaleMode(texture, c.SDL_SCALEMODE_NEAREST);
        try textures.append(allocator, texture);
    }

    return textures;
}
