const std = @import("std");
const c = @import("../c.zig").c;
const ui = @import("../ui/ui.zig");

const scene = @import("type.zig");
const socket = @import("../net/socket.zig");

pub const JoinScene = struct {
    input_code: ui.Input,
    btn_create: ui.Button,
    btn_join: ui.Button,

    label_or: ui.Label,

    ticks_ms: u64 = 0,

    t: ui.Theme,

    pub fn init(renderer: *c.SDL_Renderer) !JoinScene {
        const t = ui.Theme{
            .bg = .{ .r = 0x1a, .g = 0x1c, .b = 0x2c },
            .bg_dark = .{ .r = 0x0f, .g = 0x10, .b = 0x18 },

            .text = .{ .r = 0xe8, .g = 0xe8, .b = 0xf0 },
            .text_disabled = .{ .r = 0xae, .g = 0xae, .b = 0xbf },

            .cursor = .{ .r = 0xff, .g = 0xff, .b = 0xff },
            .font_scale = 1,
            .btn_primary = try .init(renderer, "assets/ui/box.png", 4, 4, 4, 6),
        };

        return JoinScene{ .btn_create = ui.Button.init(.{ .x = 20, .y = 130, .w = 100, .h = 40, .label = "Create" }), .input_code = ui.Input.init(.{ .x = 20, .y = 40, .w = 100, .h = 25, .placeholder = "000000", .max_len = 6, .mode = .digits }), .btn_join = ui.Button.init(.{ .x = 20, .y = 67, .w = 100, .h = 25, .label = "Join" }), .label_or = ui.Label.init(.{ .x = 62, .y = 105, .text = "or" }), .t = t };
    }

    pub fn update(self: *JoinScene, dt: f32) void {
        self.ticks_ms += @intFromFloat(dt * 1000.0);
    }

    pub fn handleEvent(self: *JoinScene, allocator: std.mem.Allocator, ev: ui.UiEvent, window: *c.SDL_Window) !?scene.Scene {
        self.input_code.handleEvent(ev, window);
        const r = self.btn_create.handleEvent(ev);
        if (r == .clicked) {
            try socket.send(.{ .clientCreateLobby = .{} });
            return scene.Scene{ .game = try scene.GameScene.init(allocator) };
        }

        const r2 = self.btn_join.handleEvent(ev);
        if (r2 == .clicked) {
            const text = self.input_code.buf[0..self.input_code.len];
            if (text.len != 6) return null;
            const code = std.fmt.parseInt(u32, text, 10) catch {
                std.debug.print("Invalid lobby code\n", .{});
                return null;
            };
            try socket.send(.{ .clientJoinLobby = .{ .id = code } });
            return scene.Scene{ .game = try scene.GameScene.init(allocator) };
        }

        return null;
    }

    pub fn draw(self: *JoinScene, r: *c.SDL_Renderer) void {
        const blink = (self.ticks_ms / 500) % 2 == 0;

        self.input_code.draw(r, self.t, blink);
        self.btn_create.draw(r, self.t);
        self.btn_join.draw(r, self.t);
        self.label_or.draw(r, self.t);
    }

    pub fn deinit(self: *JoinScene) void {
        self.t.deinit();
    }
};
