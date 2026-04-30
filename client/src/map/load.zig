const std = @import("std");
const parse = @import("parse.zig");
const tile = @import("tile.zig");
const c = @import("../c.zig").c;
const assets = @import("../assets/load.zig");
const camera_mod = @import("../camera.zig");

const MapTileset = struct {
    firstgid: u32,
    source: []const u8,
};

const TsxTileset = struct {
    name: []const u8,
    tilewidth: u32,
    tileheight: u32,
    image: []const u8,
};

fn parseTsx(allocator: std.mem.Allocator, xml: []const u8) !TsxTileset {
    const name = extractAttr(allocator, xml, "name");
    const tilewidth = try extractInt(allocator, xml, "tilewidth");
    const tileheight = try extractInt(allocator, xml, "tileheight");
    const image = extractAttr(allocator, xml, "source");

    return .{
        .name = name,
        .tilewidth = tilewidth,
        .tileheight = tileheight,
        .image = image,
    };
}

fn extractAttr(alloc: std.mem.Allocator, xml: []const u8, key: []const u8) []const u8 {
    const pattern = std.fmt.allocPrint(alloc, "{s}=\"", .{key}) catch unreachable;
    const start = std.mem.indexOf(u8, xml, pattern).?;
    const value_start = start + pattern.len;

    const end = std.mem.indexOfScalar(u8, xml[value_start..], '"').? + value_start;
    return xml[value_start..end];
}

fn extractInt(alloc: std.mem.Allocator, xml: []const u8, key: []const u8) !u32 {
    const str = extractAttr(alloc, xml, key);
    const num = std.fmt.parseInt(u32, str, 10) catch return error.InvalidNumber;
    return num;
}

pub const Layer = struct {
    tiles: std.ArrayList(tile.Tile),

    pub fn deinit(self: *Layer, alloc: std.mem.Allocator) void {
        self.tiles.deinit(alloc);
    }
};

pub const Map = struct {
    layers: std.ArrayList(Layer),
    tileset: *c.SDL_Texture,
    tilewidth: u32,
    tileheight: u32,
    tile_target: *c.SDL_Texture,

    pub fn load(allocator: std.mem.Allocator, r: *c.SDL_Renderer, path: []const u8) !Map {
        const json_bytes = try std.fs.cwd().readFileAlloc(allocator, path, 1024 * 1024);
        defer allocator.free(json_bytes);

        const parsed = try parse.loadBytes(allocator, json_bytes);
        defer parsed.deinit();
        const value = parsed.value;
        const ts = value.tilesets[0];

        var layers: std.ArrayList(Layer) = try .initCapacity(allocator, value.layers.len);

        var biggestLayerWidth: u32 = 0;
        var biggestLayerHeight: u32 = 0;

        for (value.layers) |layer| {
            try layers.append(allocator, Layer{
                .tiles = .empty,
            });

            const decoded = try parse.decodeBase64(allocator, layer.data);
            defer allocator.free(decoded);

            const tiles = parse.bytesToTiles(decoded);

            const width = layer.width;
            const height = layer.height;

            if (width > biggestLayerWidth) {
                biggestLayerWidth = width;
            }
            if (height > biggestLayerHeight) {
                biggestLayerHeight = height;
            }

            for (tiles, 0..) |t, i| {
                if (t != 0) {
                    const x = i % width;
                    const y = i / width;

                    const newTile = tile.Tile{
                        .x = @intCast(x),
                        .y = @intCast(y),
                        .texture_i = t - ts.firstgid,
                    };
                    try layers.items[layers.items.len - 1].tiles.append(allocator, newTile);
                }
            }
        }

        const tsx_file = std.fs.path.basename(ts.source);
        const tsx_path = try std.fs.path.join(allocator, &[_][]const u8{ "assets/tiles", tsx_file });
        defer allocator.free(tsx_path);
        const tsx_bytes = try std.fs.cwd().readFileAlloc(allocator, tsx_path, 1024 * 1024);
        defer allocator.free(tsx_bytes);

        const tileset_info = try parseTsx(allocator, tsx_bytes);

        const image_path = try std.fs.path.joinZ(allocator, &[_][]const u8{ "assets/tiles", tileset_info.image });
        defer allocator.free(image_path);
        const img = assets.load(r, image_path);

        const tile_target = c.SDL_CreateTexture(r, c.SDL_PIXELFORMAT_RGBA8888, c.SDL_TEXTUREACCESS_TARGET, @intCast(biggestLayerWidth * tileset_info.tilewidth), @intCast(biggestLayerHeight * tileset_info.tileheight));
        _ = c.SDL_SetTextureScaleMode(tile_target, c.SDL_SCALEMODE_NEAREST);

        return Map{
            .layers = layers,
            .tileset = img,
            .tilewidth = tileset_info.tilewidth,
            .tileheight = tileset_info.tileheight,
            .tile_target = tile_target,
        };
    }

    pub fn draw(self: *Map, r: *c.SDL_Renderer, camera: camera_mod.Camera) void {
        var image_width: f32 = 0;
        var image_height: f32 = 0;
        _ = c.SDL_GetTextureSize(self.tileset, &image_width, &image_height);

        const img_w: u32 = @intFromFloat(image_width);

        const tiles_per_row = img_w / self.tilewidth;

        const canvas = c.SDL_GetRenderTarget(r);
        _ = c.SDL_SetRenderTarget(r, self.tile_target);
        _ = c.SDL_RenderClear(r);

        for (self.layers.items) |*layer| {
            for (layer.tiles.items) |*t| {
                t.draw(r, tiles_per_row, self.tilewidth, self.tileheight, self.tileset);
            }
        }

        _ = c.SDL_SetRenderTarget(r, canvas);

        var target_width: f32 = 0;
        var target_height: f32 = 0;
        _ = c.SDL_GetTextureSize(self.tile_target, &target_width, &target_height);

        var dst_pos: [2]f32 = .{ 0, 0 };
        var dst_rotation: f32 = 0;
        camera.apply(&dst_pos, &dst_rotation);

        const pivot = c.SDL_FPoint{
            .x = camera.x,
            .y = camera.y,
        };

        const dst = c.SDL_FRect{
            .x = 160.0 - camera.x,
            .y = 120.0 - camera.y,
            .w = target_width,
            .h = target_height,
        };
        _ = c.SDL_RenderTextureRotated(r, self.tile_target, null, &dst, dst_rotation, &pivot, c.SDL_FLIP_NONE);
    }

    pub fn deinit(self: *Map, allocator: std.mem.Allocator) void {
        for (self.layers.items) |*layer| {
            layer.deinit(allocator);
        }
        self.layers.deinit(allocator);
        c.SDL_DestroyTexture(self.tileset);
        c.SDL_DestroyTexture(self.tile_target);
    }
};
