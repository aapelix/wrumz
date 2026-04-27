const c = @import("../c.zig").c;
const theme_mod = @import("theme.zig");
const draw_mod = @import("draw.zig");

pub const LabelConfig = struct {
    x: f32,
    y: f32,
    text: []const u8,
};

pub const Label = struct {
    x: f32,
    y: f32,
    text_buf: [128]u8,
    text_len: usize,

    pub fn init(cfg: LabelConfig) Label {
        var lbl = Label{
            .x = cfg.x,
            .y = cfg.y,
            .text_buf = undefined,
            .text_len = 0,
        };

        const len = @min(cfg.text.len, 127);
        @memcpy(lbl.text_buf[0..len], cfg.text[0..len]);
        lbl.text_buf[len] = 0;
        lbl.text_len = len;

        return lbl;
    }

    pub fn setText(self: *Label, text: []const u8) void {
        const len = @min(text.len, 127);
        @memcpy(self.text_buf[0..len], text[0..len]);
        self.text_buf[len] = 0;
        self.text_len = len;
    }

    pub fn draw(self: *const Label, renderer: *c.SDL_Renderer, t: theme_mod.Theme) void {
        const text_col = t.text;
        draw_mod.drawText(
            renderer,
            self.x,
            self.y,
            self.text_buf[0..self.text_len :0].ptr,
            text_col,
            t.font_scale,
        );
    }
};
