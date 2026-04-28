const c = @import("../c.zig").c;
const theme = @import("theme.zig");
const slice_mod = @import("slice.zig");
const Color = theme.Color;

pub fn fillRect(renderer: *c.SDL_Renderer, x: f32, y: f32, w: f32, h: f32, col: Color) void {
    col.set(renderer);
    const r = c.SDL_FRect{ .x = x, .y = y, .w = w, .h = h };
    _ = c.SDL_RenderFillRect(renderer, &r);
}

pub fn drawRect(renderer: *c.SDL_Renderer, x: f32, y: f32, w: f32, h: f32, thickness: f32, col: Color) void {
    col.set(renderer);
    const top = c.SDL_FRect{ .x = x, .y = y, .w = w, .h = thickness };
    _ = c.SDL_RenderFillRect(renderer, &top);
    const bot = c.SDL_FRect{ .x = x, .y = y + h - thickness, .w = w, .h = thickness };
    _ = c.SDL_RenderFillRect(renderer, &bot);
    const lft = c.SDL_FRect{ .x = x, .y = y + thickness, .w = thickness, .h = h - thickness * 2 };
    _ = c.SDL_RenderFillRect(renderer, &lft);
    const rgt = c.SDL_FRect{ .x = x + w - thickness, .y = y + thickness, .w = thickness, .h = h - thickness * 2 };
    _ = c.SDL_RenderFillRect(renderer, &rgt);
}

pub fn hline(renderer: *c.SDL_Renderer, x: f32, y: f32, len: f32, col: Color) void {
    fillRect(renderer, x, y, len, 1, col);
}

pub fn textWidth(text: []const u8, font_scale: u8) f32 {
    return @as(f32, @floatFromInt(text.len)) * 8 * @as(f32, @floatFromInt(font_scale));
}

pub fn textHeight(font_scale: u8) f32 {
    return 8 * @as(f32, @floatFromInt(font_scale));
}

pub fn drawText(renderer: *c.SDL_Renderer, x: f32, y: f32, text: [*:0]const u8, col: Color, font_scale: u8) void {
    col.set(renderer);
    const fs: f32 = @floatFromInt(font_scale);
    _ = c.SDL_SetRenderScale(renderer, fs, fs);
    const sx: f32 = x / fs;
    const sy: f32 = y / fs;
    _ = c.SDL_RenderDebugText(renderer, sx, sy, text);
    _ = c.SDL_SetRenderScale(renderer, 1.0, 1.0);
}

pub fn drawTextSlice(renderer: *c.SDL_Renderer, x: i32, y: i32, text: []const u8, col: Color, font_scale: u8) void {
    var buf: [256]u8 = undefined;
    const len = @min(text.len, buf.len - 1);
    @memcpy(buf[0..len], text[0..len]);
    buf[len] = 0;
    drawText(renderer, x, y, buf[0..len :0].ptr, col, font_scale);
}

pub const drawNineSlice = slice_mod.drawNineSlice;
