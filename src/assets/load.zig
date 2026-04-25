const std = @import("std");
const sdl = @import("../sdl.zig").c;

pub fn load(renderer: *sdl.SDL_Renderer, path: [*:0]const u8) *sdl.SDL_Texture {
    const image = sdl.SDL_LoadPNG(path);
    if (image == null) {
        @panic("failed to load image");
    }

    defer sdl.SDL_DestroySurface(image);

    return sdl.SDL_CreateTextureFromSurface(renderer, image);
}

pub fn loadFolder(renderer: *sdl.SDL_Renderer, path: []const u8) ![]*sdl.SDL_Texture {
    var textures: std.ArrayList(*sdl.SDL_Texture) = .empty;

    var dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();

    while (try iter.next()) |entry| {
        if (entry.kind == .file) {
            const file_path = std.fs.path.joinZ(std.heap.page_allocator, &.{ path, entry.name }) catch {
                @panic("failed to join path");
            };

            const texture = load(renderer, file_path);
            try textures.append(std.heap.page_allocator, texture);
        }
    }

    return textures.toOwnedSlice(std.heap.page_allocator);
}
