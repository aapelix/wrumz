const c = @import("../c.zig").c;
const slice_mod = @import("slice.zig");

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,

    pub fn toSDL(self: Color) void {
        _ = self;
    }

    pub fn set(self: Color, r: *c.SDL_Renderer) void {
        _ = c.SDL_SetRenderDrawColor(r, self.r, self.g, self.b, self.a);
    }
};

pub const Theme = struct {
    bg: Color,
    bg_dark: Color,
    text: Color,
    text_disabled: Color,
    cursor: Color,

    font_scale: u8,

    btn_primary: ?slice_mod.NineSlice = null,

    pub fn deinit(self: *Theme) void {
        if (self.btn_primary != null) self.btn_primary.?.deinit();
    }
};

pub const default: Theme = .{
    .bg = .{ .r = 0x1a, .g = 0x1c, .b = 0x2c },
    .bg_dark = .{ .r = 0x0f, .g = 0x10, .b = 0x18 },

    .text = .{ .r = 0xe8, .g = 0xe8, .b = 0xf0 },
    .text_disabled = .{ .r = 0x7b, .g = 0x7b, .b = 0xab },

    .cursor = .{ .r = 0xff, .g = 0xff, .b = 0xff },
    .font_scale = 1,

    .btn_primary = null,
};
