const std = @import("std");
const Message = @import("msg").Message;

const c = @import("../c.zig").c;
pub const GameScene = @import("game.zig").GameScene;

pub const Scene = union(enum) {
    game: GameScene,
    pub fn update(self: *Scene, dt: f32) !void {
        switch (self.*) {
            .game => |*g| try g.update(dt),
        }
    }

    pub fn handleMsg(self: *Scene, allocator: std.mem.Allocator, renderer: *c.SDL_Renderer, msg: Message) !void {
        switch (self.*) {
            .game => |*g| try g.handleMsg(allocator, renderer, msg),
        }
    }

    pub fn draw(self: *Scene, renderer: *c.SDL_Renderer) void {
        switch (self.*) {
            .game => |*g| g.draw(renderer),
        }
    }

    pub fn deinit(self: *Scene, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .game => |*g| g.deinit(allocator),
        }
    }
};

pub const SceneManager = struct {
    current: Scene,

    pub fn update(self: *SceneManager, dt: f32) !void {
        try self.current.update(dt);
    }

    pub fn handleMsg(self: *SceneManager, allocator: std.mem.Allocator, renderer: *c.SDL_Renderer, msg: Message) !void {
        try self.current.handleMsg(allocator, renderer, msg);
    }

    pub fn draw(self: *SceneManager, renderer: *c.SDL_Renderer) void {
        self.current.draw(renderer);
    }

    pub fn set(self: *SceneManager, scene: Scene) void {
        self.current = scene;
    }

    pub fn deinit(self: *SceneManager, allocator: std.mem.Allocator) void {
        self.current.deinit(allocator);
    }
};
