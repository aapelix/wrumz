const std = @import("std");

pub const ParseMap = struct {
    width: u32,
    height: u32,
    tilewidth: u32,
    tileheight: u32,
    layers: []ParseLayer,
    tilesets: []ParseTileset,
};

pub const ParseLayer = struct {
    id: u32,
    name: []const u8,
    width: u32,
    height: u32,
    data: []const u8, // base64
};

pub const ParseTileset = struct {
    firstgid: u32,
    source: []const u8,
};

/// The caller is responsible for freeing the returned byte array using the provided allocator.
pub fn decodeBase64(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const decoder = std.base64.standard.Decoder;
    const size = try decoder.calcSizeForSlice(input);
    const out = try allocator.alloc(u8, size);
    try decoder.decode(out, input);
    return out;
}

pub fn bytesToTiles(bytes: []const u8) []const u32 {
    return @alignCast(std.mem.bytesAsSlice(u32, bytes));
}

/// The caller is responsible for freeing the returned `Parsed(ParseMap)` using the provided allocator.
pub fn loadBytes(allocator: std.mem.Allocator, json_bytes: []const u8) !std.json.Parsed(ParseMap) {
    const parsed: std.json.Parsed(ParseMap) = try std.json.parseFromSlice(ParseMap, allocator, json_bytes, .{
        .ignore_unknown_fields = true,
    });
    return parsed;
}
