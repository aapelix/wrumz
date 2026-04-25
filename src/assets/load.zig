const std = @import("std");
const sdl = @import("../sdl.zig").c;

pub fn load(renderer: *sdl.SDL_Renderer, path: [*:0]const u8) *sdl.SDL_Texture {
    const image = sdl.SDL_LoadPNG(path);
    if (image == null) {
        @panic("failed to load image");
    }

    defer sdl.SDL_DestroySurface(image);

    const texture = sdl.SDL_CreateTextureFromSurface(renderer, image);
    _ = sdl.SDL_SetTextureScaleMode(texture, sdl.SDL_SCALEMODE_NEAREST);

    return texture;
}

pub fn loadFolder(allocator: std.mem.Allocator, renderer: *sdl.SDL_Renderer, path: []const u8, count: usize) !std.ArrayList(*sdl.SDL_Texture) {
    var textures: std.ArrayList(*sdl.SDL_Texture) = try .initCapacity(allocator, count + 1);

    for (0..count) |i| {
        var buf: [256]u8 = undefined;
        const file_path = try std.fmt.bufPrintZ(&buf, "{s}/img_{d}.png", .{ path, i + 1 });

        const texture = load(renderer, file_path);
        _ = sdl.SDL_SetTextureScaleMode(texture, sdl.SDL_SCALEMODE_NEAREST);
        try textures.append(allocator, texture);
    }

    return textures;
}
