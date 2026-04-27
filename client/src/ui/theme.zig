const c = @import("../c.zig").c;

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
    border: Color,
    border_focus: Color,
    text: Color,
    text_disabled: Color,
    accent: Color,
    accent_hover: Color,
    accent_press: Color,
    cursor: Color,

    font_scale: u8,
    pad_x: u8,
    pad_y: u8,
    border_px: u8,
};

pub const default: Theme = .{
    .bg = .{ .r = 0x1a, .g = 0x1c, .b = 0x2c },
    .bg_dark = .{ .r = 0x0f, .g = 0x10, .b = 0x18 },
    .border = .{ .r = 0x44, .g = 0x44, .b = 0x66 },
    .border_focus = .{ .r = 0x99, .g = 0xdd, .b = 0xff },
    .text = .{ .r = 0xe8, .g = 0xe8, .b = 0xf0 },
    .text_disabled = .{ .r = 0x55, .g = 0x55, .b = 0x77 },
    .accent = .{ .r = 0x33, .g = 0x77, .b = 0xcc },
    .accent_hover = .{ .r = 0x44, .g = 0x99, .b = 0xff },
    .accent_press = .{ .r = 0x22, .g = 0x55, .b = 0xaa },
    .cursor = .{ .r = 0xff, .g = 0xff, .b = 0xff },
    .font_scale = 1,
    .pad_x = 4,
    .pad_y = 3,
    .border_px = 1,
};
