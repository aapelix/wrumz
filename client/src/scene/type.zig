const std = @import("std");
const Message = @import("msg").Message;

const ui = @import("../ui/ui.zig");

const c = @import("../c.zig").c;
pub const GameScene = @import("game.zig").GameScene;
pub const JoinScene = @import("join.zig").JoinScene;

pub const Scene = union(enum) {
    game: GameScene,
    join: JoinScene,

    pub fn update(self: *Scene, dt: f32) !void {
        switch (self.*) {
            .game => |*g| try g.update(dt),
            .join => |*j| j.update(dt),
        }
    }

    pub fn handleMsg(self: *Scene, allocator: std.mem.Allocator, renderer: *c.SDL_Renderer, msg: Message) !void {
        switch (self.*) {
            .game => |*g| try g.handleMsg(allocator, renderer, msg),
            else => {},
        }
    }

    pub fn handleEvent(self: *Scene, alloc: std.mem.Allocator, ev: ui.UiEvent, window: *c.SDL_Window) !?Scene {
        const s = switch (self.*) {
            .join => |*j| try j.handleEvent(alloc, ev, window),
            else => {
                return null;
            },
        };

        if (s) |new_scene| {
            return new_scene;
        } else {
            return null;
        }
    }

    pub fn draw(self: *Scene, renderer: *c.SDL_Renderer) void {
        switch (self.*) {
            .game => |*g| g.draw(renderer),
            .join => |*j| j.draw(renderer),
        }
    }

    pub fn deinit(self: *Scene, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .game => |*g| g.deinit(allocator),
            .join => |*j| j.deinit(),
        }
    }
};

pub const SceneManager = struct {
    current: Scene,
    allocator: std.mem.Allocator,

    pub fn update(self: *SceneManager, dt: f32) !void {
        try self.current.update(dt);
    }

    pub fn handleMsg(self: *SceneManager, renderer: *c.SDL_Renderer, msg: Message) !void {
        try self.current.handleMsg(self.allocator, renderer, msg);
    }

    pub fn handleEvent(self: *SceneManager, event: ui.UiEvent, window: *c.SDL_Window) !void {
        const s = try self.current.handleEvent(self.allocator, event, window);
        if (s) |new_scene| {
            self.deinit();
            self.set(new_scene);
        }
    }

    pub fn draw(self: *SceneManager, renderer: *c.SDL_Renderer) void {
        self.current.draw(renderer);
    }

    pub fn set(self: *SceneManager, scene: Scene) void {
        self.current = scene;
    }

    pub fn deinit(self: *SceneManager) void {
        self.current.deinit(self.allocator);
    }
};
