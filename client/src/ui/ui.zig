const theme_mod = @import("theme.zig");
pub const Theme = theme_mod.Theme;
pub const default_theme = theme_mod.default;

const event_mod = @import("event.zig");
pub const UiEvent = event_mod.UiEvent;
pub const Key = event_mod.Key;
pub const MouseButton = event_mod.MouseButton;

const button_mod = @import("button.zig");
pub const Button = button_mod.Button;
pub const ButtonConfig = button_mod.ButtonConfig;
pub const ButtonStyle = button_mod.ButtonStyle;
pub const ButtonResult = button_mod.ButtonResult;

const input_mod = @import("input.zig");
pub const Input = input_mod.Input;
pub const InputConfig = input_mod.InputConfig;

const label_mod = @import("label.zig");
pub const Label = label_mod.Label;
pub const LabelConfig = label_mod.LabelConfig;

const slice_mod = @import("slice.zig");
pub const NineSlice = slice_mod.NineSlice;

pub const draw = @import("draw.zig");

const c = @import("../c.zig").c;
const std = @import("std");

pub fn mapEvent(
    e: *const c.SDL_Event,
    offset_x: f32,
    offset_y: f32,
    scale: f32,
) ?UiEvent {
    switch (e.type) {
        c.SDL_EVENT_MOUSE_MOTION => {
            const mx = (e.motion.x - offset_x) / scale;
            const my = (e.motion.y - offset_y) / scale;
            return .{ .mouse_move = .{ .x = mx, .y = my } };
        },
        c.SDL_EVENT_MOUSE_BUTTON_DOWN => {
            const mx = (e.button.x - offset_x) / scale;
            const my = (e.button.y - offset_y) / scale;
            const btn = sdlButtonToUi(e.button.button);
            return .{ .mouse_down = .{ .x = mx, .y = my, .button = btn } };
        },
        c.SDL_EVENT_MOUSE_BUTTON_UP => {
            const mx = (e.button.x - offset_x) / scale;
            const my = (e.button.y - offset_y) / scale;
            const btn = sdlButtonToUi(e.button.button);
            return .{ .mouse_up = .{ .x = mx, .y = my, .button = btn } };
        },
        c.SDL_EVENT_TEXT_INPUT => {
            const raw: [*:0]const u8 = e.text.text;
            const byte = raw[0];
            if (byte == 0) return null;
            if (byte < 0x80) return .{ .text_input = byte };
            var buf: [4]u8 = undefined;
            var i: usize = 0;
            while (raw[i] != 0 and i < 4) : (i += 1) buf[i] = raw[i];
            const decoded = std.unicode.utf8Decode(buf[0..i]) catch return null;
            return .{ .text_input = decoded };
        },
        c.SDL_EVENT_KEY_DOWN => {
            const k = sdlKeyToUi(e.key.key);
            return .{ .key_down = k };
        },
        else => return null,
    }
}

fn sdlButtonToUi(btn: u8) MouseButton {
    return switch (btn) {
        c.SDL_BUTTON_LEFT => .left,
        c.SDL_BUTTON_RIGHT => .right,
        c.SDL_BUTTON_MIDDLE => .middle,
        else => .left,
    };
}

fn sdlKeyToUi(key: c.SDL_Keycode) Key {
    return switch (key) {
        c.SDLK_BACKSPACE => .backspace,
        c.SDLK_RETURN, c.SDLK_KP_ENTER => .@"return",
        c.SDLK_ESCAPE => .escape,
        c.SDLK_LEFT => .left,
        c.SDLK_RIGHT => .right,
        c.SDLK_HOME => .home,
        c.SDLK_END => .end,
        c.SDLK_DELETE => .delete,
        c.SDLK_TAB => .tab,
        else => .other,
    };
}
