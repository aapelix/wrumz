const c = @import("../c.zig").c;
const theme_mod = @import("theme.zig");
const draw_mod = @import("draw.zig");
const slice_mod = @import("slice.zig");
const event_mod = @import("event.zig");

const std = @import("std");

const Theme = theme_mod.Theme;
const UiEvent = event_mod.UiEvent;

pub const ButtonState = enum { normal, hovered, pressed, disabled };

pub const ButtonResult = enum { none, clicked };

pub const ButtonStyle = enum {
    primary,
};

pub const ButtonConfig = struct {
    x: f32,
    y: f32,
    w: f32,
    h: f32,
    label: []const u8,
    style: ButtonStyle = .primary,
    disabled: bool = false,
};

pub const Button = struct {
    x: f32,
    y: f32,
    w: f32,
    h: f32,
    label_buf: [64]u8,
    label_len: usize,
    style: ButtonStyle,
    state: ButtonState,

    pub fn init(cfg: ButtonConfig) Button {
        var btn = Button{
            .x = cfg.x,
            .y = cfg.y,
            .w = cfg.w,
            .h = cfg.h,
            .label_buf = undefined,
            .label_len = 0,
            .style = cfg.style,
            .state = if (cfg.disabled) .disabled else .normal,
        };
        const len = @min(cfg.label.len, 63);
        @memcpy(btn.label_buf[0..len], cfg.label[0..len]);
        btn.label_buf[len] = 0;
        btn.label_len = len;
        return btn;
    }

    pub fn setLabel(self: *Button, label: []const u8) void {
        const len = @min(label.len, 63);
        @memcpy(self.label_buf[0..len], label[0..len]);
        self.label_buf[len] = 0;
        self.label_len = len;
    }

    pub fn setDisabled(self: *Button, disabled: bool) void {
        if (disabled) {
            self.state = .disabled;
        } else if (self.state == .disabled) {
            self.state = .normal;
        }
    }

    fn contains(self: *const Button, mx: f32, my: f32) bool {
        return mx >= self.x and mx < self.x + self.w and
            my >= self.y and my < self.y + self.h;
    }

    pub fn handleEvent(self: *Button, ev: UiEvent) ButtonResult {
        if (self.state == .disabled) return .none;
        switch (ev) {
            .mouse_move => |m| {
                if (self.state == .pressed) return .none;
                self.state = if (self.contains(m.x, m.y)) .hovered else .normal;
            },
            .mouse_down => |m| {
                if (m.button == .left and self.contains(m.x, m.y)) {
                    self.state = .pressed;
                }
            },
            .mouse_up => |m| {
                if (m.button == .left) {
                    const was_pressed = self.state == .pressed;
                    self.state = if (self.contains(m.x, m.y)) .hovered else .normal;
                    if (was_pressed and self.contains(m.x, m.y)) return .clicked;
                }
            },
            else => {},
        }
        return .none;
    }

    pub fn draw(self: *const Button, renderer: *c.SDL_Renderer, t: Theme) void {
        const text_col = if (self.state == .disabled) t.text_disabled else t.text;

        const oy: f32 = switch (self.state) {
            .normal => 0,
            .hovered => -1,
            .pressed => 1,
            .disabled => 0,
        };

        const oh = -oy;

        const maybe_slice: ?slice_mod.NineSlice = switch (self.style) {
            .primary => t.btn_primary,
        };

        if (maybe_slice) |ns| {
            draw_mod.drawNineSlice(renderer, ns, self.x, self.y + oy, self.w, self.h + oh);
        }

        const tw = draw_mod.textWidth(self.label_buf[0..self.label_len], t.font_scale);
        const th = draw_mod.textHeight(t.font_scale);
        const tx = self.x + @divTrunc(self.w - tw, 2);
        const ty = self.y + oy + @divTrunc(self.h - th, 2);
        draw_mod.drawText(renderer, tx, ty, self.label_buf[0..self.label_len :0].ptr, text_col, t.font_scale);
    }
};
