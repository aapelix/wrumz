const std = @import("std");
const c = @import("../c.zig").c;
const theme_mod = @import("theme.zig");
const draw_mod = @import("draw.zig");
const event_mod = @import("event.zig");
const slice_mod = @import("slice.zig");

const Theme = theme_mod.Theme;
const UiEvent = event_mod.UiEvent;

pub const InputMode = enum {
    normal,
    digits,
};

pub const InputConfig = struct {
    x: f32,
    y: f32,
    w: f32,
    h: f32,
    placeholder: []const u8 = "",
    max_len: usize = 63,
    password: bool = false,
    disabled: bool = false,
    mode: InputMode = .normal,
};

pub const Input = struct {
    x: f32,
    y: f32,
    w: f32,
    h: f32,
    password: bool,
    disabled: bool,
    max_len: usize,

    buf: [64]u8,
    len: usize,

    placeholder_buf: [64]u8,
    placeholder_len: usize,

    cursor: usize,

    focused: bool,

    mode: InputMode,

    pub fn init(cfg: InputConfig) Input {
        var inp = Input{
            .x = cfg.x,
            .y = cfg.y,
            .w = cfg.w,
            .h = cfg.h,
            .password = cfg.password,
            .disabled = cfg.disabled,
            .max_len = @min(cfg.max_len, 63),
            .buf = undefined,
            .len = 0,
            .placeholder_buf = undefined,
            .placeholder_len = 0,
            .cursor = 0,
            .focused = false,
            .mode = cfg.mode,
        };
        inp.buf[0] = 0;
        const pl = @min(cfg.placeholder.len, 63);
        @memcpy(inp.placeholder_buf[0..pl], cfg.placeholder[0..pl]);
        inp.placeholder_buf[pl] = 0;
        inp.placeholder_len = pl;
        return inp;
    }

    pub fn text(self: *const Input) []const u8 {
        return self.buf[0..self.len];
    }

    pub fn setValue(self: *Input, val: []const u8) void {
        const n = @min(val.len, self.max_len);
        @memcpy(self.buf[0..n], val[0..n]);
        self.buf[n] = 0;
        self.len = n;
        self.cursor = n;
    }

    pub fn clear(self: *Input) void {
        self.len = 0;
        self.cursor = 0;
        self.buf[0] = 0;
    }

    pub fn focus(self: *Input) void {
        self.focused = true;
    }

    pub fn blur(self: *Input) void {
        self.focused = false;
    }

    fn contains(self: *const Input, mx: f32, my: f32) bool {
        return mx >= self.x and mx < self.x + self.w and
            my >= self.y and my < self.y + self.h;
    }

    fn insertChar(self: *Input, cp: u21) void {
        if (self.len >= self.max_len) return;
        if (cp > 0x7e or cp < 0x20) return;
        if (self.mode == .digits and (cp < '0' or cp > '9')) return;
        var i = self.len;
        while (i > self.cursor) : (i -= 1) {
            self.buf[i] = self.buf[i - 1];
        }
        self.buf[self.cursor] = @intCast(cp);
        self.len += 1;
        self.cursor += 1;
        self.buf[self.len] = 0;
    }

    fn deleteBack(self: *Input) void {
        if (self.cursor == 0) return;
        var i = self.cursor - 1;
        while (i < self.len - 1) : (i += 1) {
            self.buf[i] = self.buf[i + 1];
        }
        self.len -= 1;
        self.cursor -= 1;
        self.buf[self.len] = 0;
    }

    fn deleteForward(self: *Input) void {
        if (self.cursor >= self.len) return;
        var i = self.cursor;
        while (i < self.len - 1) : (i += 1) {
            self.buf[i] = self.buf[i + 1];
        }
        self.len -= 1;
        self.buf[self.len] = 0;
    }

    pub fn handleEvent(self: *Input, ev: UiEvent, window: *c.SDL_Window) void {
        if (self.disabled) return;
        switch (ev) {
            .mouse_down => |m| {
                if (m.button == .left) {
                    if (self.contains(m.x, m.y)) {
                        self.focused = true;
                        const bp: f32 = 1;
                        const px = self.x + bp + 2;
                        const rel = m.x - px;
                        const glyph_w: f32 = 8;
                        const idx: usize = @intFromFloat(@max(0, @divTrunc(rel + glyph_w / 2, glyph_w)));
                        self.cursor = @min(idx, self.len);
                        _ = c.SDL_StartTextInput(window);
                    } else {
                        self.focused = false;
                        _ = c.SDL_StopTextInput(window);
                    }
                }
            },
            .blur => {
                self.focused = false;
                _ = c.SDL_StopTextInput(window);
            },
            .text_input => |cp| {
                if (self.focused) self.insertChar(cp);
            },
            .key_down => |k| {
                if (!self.focused) return;
                switch (k) {
                    .backspace => self.deleteBack(),
                    .delete => self.deleteForward(),
                    .left => {
                        if (self.cursor > 0) self.cursor -= 1;
                    },
                    .right => {
                        if (self.cursor < self.len) self.cursor += 1;
                    },
                    .home => self.cursor = 0,
                    .end => self.cursor = self.len,
                    else => {},
                }
            },
            else => {},
        }
    }

    pub fn draw(self: *const Input, renderer: *c.SDL_Renderer, t: Theme, blink_on: bool) void {
        if (t.btn_primary) |ns| {
            draw_mod.drawNineSlice(renderer, ns, self.x, self.y, self.w, self.h);

            const cx = self.x + @as(f32, @floatFromInt(ns.left)) + 2;
            const cy = self.y + @divTrunc(self.h - draw_mod.textHeight(t.font_scale), 2);

            if (self.len == 0 and !self.focused) {
                if (self.placeholder_len > 0) {
                    draw_mod.drawText(
                        renderer,
                        cx,
                        cy,
                        self.placeholder_buf[0..self.placeholder_len :0].ptr,
                        t.text_disabled,
                        t.font_scale,
                    );
                }
            } else {
                var disp: [64]u8 = undefined;
                if (self.password) {
                    var i: usize = 0;
                    while (i < self.len) : (i += 1) disp[i] = 0xb7; // middle dot
                    disp[self.len] = 0;
                } else {
                    @memcpy(disp[0..self.len], self.buf[0..self.len]);
                    disp[self.len] = 0;
                }

                const tc = if (self.disabled) t.text_disabled else t.text;
                draw_mod.drawText(renderer, cx, cy, disp[0..self.len :0].ptr, tc, t.font_scale);
            }

            if (self.focused and blink_on) {
                const glyph_w: f32 = 8 * @as(f32, @floatFromInt(t.font_scale));
                const cur_x = cx + @as(f32, @floatFromInt(self.cursor)) * glyph_w;
                const cur_h = draw_mod.textHeight(t.font_scale);
                draw_mod.fillRect(renderer, cur_x, cy, 1, cur_h, t.cursor);
            }
        }
    }
};
