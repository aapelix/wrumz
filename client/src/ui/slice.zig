const c = @import("../c.zig").c;
const theme_mod = @import("theme.zig");
const assets = @import("../assets/load.zig");

pub const NineSlice = struct {
    texture: ?*c.SDL_Texture,
    left: u16,
    right: u16,
    top: u16,
    bottom: u16,
    tex_w: u16,
    tex_h: u16,

    pub fn init(
        renderer: *c.SDL_Renderer,
        path: [*:0]const u8,
        left: u16,
        right: u16,
        top: u16,
        bottom: u16,
    ) !NineSlice {
        const texture = assets.load(renderer, path);
        var tex_w: f32 = 0;
        var tex_h: f32 = 0;
        _ = c.SDL_GetTextureSize(texture, &tex_w, &tex_h);
        return NineSlice{
            .texture = texture,
            .left = left,
            .right = right,
            .top = top,
            .bottom = bottom,
            .tex_w = @as(u16, @intFromFloat(tex_w)),
            .tex_h = @as(u16, @intFromFloat(tex_h)),
        };
    }

    pub fn deinit(self: *NineSlice) void {
        if (self.texture != null) {
            c.SDL_DestroyTexture(self.texture.?);
            self.texture = null;
        }
    }
};

pub fn drawNineSlice(
    renderer: *c.SDL_Renderer,
    ns: NineSlice,
    x: f32,
    y: f32,
    w: f32,
    h: f32,
) void {
    const l: f32 = @floatFromInt(ns.left);
    const r: f32 = @floatFromInt(ns.right);
    const t: f32 = @floatFromInt(ns.top);
    const b: f32 = @floatFromInt(ns.bottom);
    const tw: f32 = @floatFromInt(ns.tex_w);
    const th: f32 = @floatFromInt(ns.tex_h);

    const mid_w = w - l - r;
    const mid_h = h - t - b;

    const src = [3][3]c.SDL_FRect{
        .{
            .{ .x = 0, .y = 0, .w = l, .h = t },
            .{ .x = l, .y = 0, .w = tw - l - r, .h = t },
            .{ .x = tw - r, .y = 0, .w = r, .h = t },
        },
        .{
            .{ .x = 0, .y = t, .w = l, .h = th - t - b },
            .{ .x = l, .y = t, .w = tw - l - r, .h = th - t - b },
            .{ .x = tw - r, .y = t, .w = r, .h = th - t - b },
        },
        .{
            .{ .x = 0, .y = th - b, .w = l, .h = b },
            .{ .x = l, .y = th - b, .w = tw - l - r, .h = b },
            .{ .x = tw - r, .y = th - b, .w = r, .h = b },
        },
    };

    const dst = [3][3]c.SDL_FRect{
        .{
            .{ .x = x, .y = y, .w = l, .h = t },
            .{ .x = x + l, .y = y, .w = mid_w, .h = t },
            .{ .x = x + w - r, .y = y, .w = r, .h = t },
        },
        .{
            .{ .x = x, .y = y + t, .w = l, .h = mid_h },
            .{ .x = x + l, .y = y + t, .w = mid_w, .h = mid_h },
            .{ .x = x + w - r, .y = y + t, .w = r, .h = mid_h },
        },
        .{
            .{ .x = x, .y = y + h - b, .w = l, .h = b },
            .{ .x = x + l, .y = y + h - b, .w = mid_w, .h = b },
            .{ .x = x + w - r, .y = y + h - b, .w = r, .h = b },
        },
    };

    for (0..3) |row| {
        for (0..3) |col| {
            _ = c.SDL_RenderTexture(renderer, ns.texture, &src[row][col], &dst[row][col]);
        }
    }
}
