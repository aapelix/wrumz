const std = @import("std");
const c = @import("../c.zig").c;

pub fn load(renderer: *c.SDL_Renderer, path: [*:0]const u8) *c.SDL_Texture {
    const image = c.SDL_LoadPNG(path);
    if (image == null) {
        std.debug.print("Failed to load image: {s}\n", .{path});
        @panic("failed to load image");
    }

    defer c.SDL_DestroySurface(image);

    const texture = c.SDL_CreateTextureFromSurface(renderer, image);
    _ = c.SDL_SetTextureScaleMode(texture, c.SDL_SCALEMODE_NEAREST);

    return texture;
}

pub fn loadFolder(allocator: std.mem.Allocator, renderer: *c.SDL_Renderer, path: []const u8, count: usize) !std.ArrayList(*c.SDL_Texture) {
    var textures: std.ArrayList(*c.SDL_Texture) = try .initCapacity(allocator, count);
    errdefer {
        for (textures.items) |tex| {
            c.SDL_DestroyTexture(tex);
        }
        textures.deinit(allocator);
    }

    for (0..count - 1) |i| {
        var buf: [256]u8 = undefined;
        const file_path = try std.fmt.bufPrintZ(&buf, "{s}/img_{d}.png", .{ path, i });

        const texture = load(renderer, file_path);
        errdefer c.SDL_DestroyTexture(texture);

        _ = c.SDL_SetTextureScaleMode(texture, c.SDL_SCALEMODE_NEAREST);
        try textures.append(allocator, texture);
    }

    return textures;
}
