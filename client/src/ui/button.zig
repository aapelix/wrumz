const c = @import("../c.zig").c;
const theme_mod = @import("theme.zig");
const draw_mod = @import("draw.zig");
const event_mod = @import("event.zig");

const std = @import("std");

const Theme = theme_mod.Theme;
const UiEvent = event_mod.UiEvent;

pub const ButtonState = enum { normal, hovered, pressed, disabled };

pub const ButtonResult = enum { none, clicked };

pub const ButtonStyle = enum {
    primary,
    ghost,
    danger,
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
        const bp: f32 = @floatFromInt(t.border_px);

        const bg_col: theme_mod.Color = switch (self.style) {
            .primary => switch (self.state) {
                .normal => t.accent,
                .hovered => t.accent_hover,
                .pressed => t.accent_press,
                .disabled => t.bg_dark,
            },
            .ghost => t.bg,
            .danger => switch (self.state) {
                .normal => .{ .r = 0xaa, .g = 0x33, .b = 0x33, .a = 255 },
                .hovered => .{ .r = 0xdd, .g = 0x44, .b = 0x44, .a = 255 },
                .pressed => .{ .r = 0x88, .g = 0x22, .b = 0x22, .a = 255 },
                .disabled => t.bg_dark,
            },
        };

        const border_col: theme_mod.Color = switch (self.style) {
            .primary => switch (self.state) {
                .normal => t.accent_hover,
                .hovered => t.accent_hover,
                .pressed => t.accent,
                .disabled => t.border,
            },
            .ghost => switch (self.state) {
                .normal => t.border,
                .hovered => t.border_focus,
                .pressed => t.accent,
                .disabled => t.border,
            },
            .danger => switch (self.state) {
                .normal => .{ .r = 0xcc, .g = 0x44, .b = 0x44, .a = 255 },
                .hovered => .{ .r = 0xff, .g = 0x66, .b = 0x66, .a = 255 },
                .pressed => .{ .r = 0x88, .g = 0x22, .b = 0x22, .a = 255 },
                .disabled => t.border,
            },
        };

        const text_col = if (self.state == .disabled) t.text_disabled else t.text;

        const ox: f32 = if (self.state == .pressed) 1 else 0;
        const oy: f32 = if (self.state == .pressed) 1 else 0;

        draw_mod.fillRect(renderer, self.x + ox, self.y + oy, self.w, self.h, bg_col);
        draw_mod.drawRect(renderer, self.x + ox, self.y + oy, self.w, self.h, bp, border_col);

        const tw = draw_mod.textWidth(self.label_buf[0..self.label_len], t.font_scale);
        const th = draw_mod.textHeight(t.font_scale);
        const tx = self.x + ox + @divTrunc(self.w - tw, 2);
        const ty = self.y + oy + @divTrunc(self.h - th, 2);
        draw_mod.drawText(renderer, tx, ty, self.label_buf[0..self.label_len :0].ptr, text_col, t.font_scale);

        if (self.style == .ghost and self.state == .hovered) {
            draw_mod.hline(renderer, self.x + ox + 2, self.y + oy + self.h - 2, self.w - 4, t.border_focus);
        }
    }
};
