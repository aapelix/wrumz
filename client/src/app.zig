const std = @import("std");
const builtin = @import("builtin");

const Message = @import("msg").Message;

const c = @import("c.zig").c;

const assets = @import("assets/load.zig");
const stack = @import("stack.zig");
const socket = @import("net/socket.zig");

fn onWsMessage(m: Message) void {
    std.debug.print("got: {any}\n", .{m});
}

var window: *c.SDL_Window = undefined;
var renderer: *c.SDL_Renderer = undefined;
var canvas: *c.SDL_Texture = undefined;
var s: stack.Stack = undefined;
var rotation: f32 = 0;

var last: u64 = undefined;

const allocator = if (builtin.os.tag == .emscripten)
    std.heap.c_allocator
else
    std.heap.page_allocator;

const CANVAS_WIDTH: c_int = 320;
const CANVAS_HEIGHT: c_int = 240;

pub fn appInit(_: ?*?*anyopaque, _: [][*:0]u8) !c.SDL_AppResult {
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        return c.SDL_APP_FAILURE;
    }

    _ = c.SDL_CreateWindowAndRenderer(
        "wrum",
        1280,
        720,
        0,
        @ptrCast(&window),
        @ptrCast(&renderer),
    );

    canvas = c.SDL_CreateTexture(
        renderer,
        c.SDL_PIXELFORMAT_RGBA8888,
        c.SDL_TEXTUREACCESS_TARGET,
        320,
        240,
    );

    _ = c.SDL_SetTextureScaleMode(canvas, c.SDL_SCALEMODE_NEAREST);
    _ = c.SDL_SetTextureBlendMode(canvas, c.SDL_BLENDMODE_NONE);

    last = c.SDL_GetPerformanceCounter();

    s = try stack.Stack.init(allocator, renderer, "assets/cars", 6);

    socket.init("localhost", 23901, "ws://localhost:23901/ws");

    socket.setMessageCallback(onWsMessage);

    return c.SDL_APP_CONTINUE;
}

pub fn appIterate(_: ?*anyopaque) !c.SDL_AppResult {
    socket.poll();

    const now = c.SDL_GetPerformanceCounter();
    const dt =
        @as(f32, @floatFromInt(now - last)) /
        @as(f32, @floatFromInt(c.SDL_GetPerformanceFrequency()));
    last = now;

    rotation += 45 * dt;

    _ = c.SDL_SetRenderTarget(renderer, canvas);
    _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    _ = c.SDL_RenderClear(renderer);

    s.draw(renderer, [2]f32{ 100, 100 }, rotation);

    _ = c.SDL_SetRenderTarget(renderer, null);
    _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    _ = c.SDL_RenderClear(renderer);

    var w: c_int = undefined;
    var h: c_int = undefined;
    _ = c.SDL_GetWindowSize(window, &w, &h);

    const scale = @min(@as(f32, @floatFromInt(w)) / CANVAS_WIDTH, @as(f32, @floatFromInt(h)) / CANVAS_HEIGHT);

    const dst_w = CANVAS_WIDTH * scale;
    const dst_h = CANVAS_HEIGHT * scale;

    const x = (@as(f32, @floatFromInt(w)) - dst_w) / 2.0;
    const y = (@as(f32, @floatFromInt(h)) - dst_h) / 2.0;

    const dst_rect = c.SDL_FRect{
        .x = x,
        .y = y,
        .w = dst_w,
        .h = dst_h,
    };

    _ = c.SDL_RenderTexture(renderer, canvas, null, &dst_rect);
    _ = c.SDL_RenderPresent(renderer);

    return c.SDL_APP_CONTINUE;
}

pub fn appEvent(_: ?*anyopaque, event: *c.SDL_Event) !c.SDL_AppResult {
    if (event.type == c.SDL_EVENT_QUIT) {
        return c.SDL_APP_SUCCESS;
    }

    if (event.type == c.SDL_EVENT_KEY_DOWN) {
        if (event.key.key == c.SDL_GetKeyFromName("a")) {
            try socket.send(.{ .ping = .{ .username = "Aaro" } });
        }
    }
    return c.SDL_APP_CONTINUE;
}

pub fn appQuit(_: ?*anyopaque, _: anyerror!c.SDL_AppResult) void {
    s.deinit(allocator);

    c.SDL_DestroyTexture(canvas);
    c.SDL_DestroyRenderer(renderer);
    c.SDL_DestroyWindow(window);
    c.SDL_Quit();
}
