const std = @import("std");
const builtin = @import("builtin");
const sdl = @import("sdl.zig").c;

const assets = @import("assets/load.zig");
const stack = @import("stack.zig");

var window: *sdl.SDL_Window = undefined;
var renderer: *sdl.SDL_Renderer = undefined;
var canvas: *sdl.SDL_Texture = undefined;
var s: stack.Stack = undefined;
var rotation: f32 = 0;

var last: u64 = undefined;

const allocator = if (builtin.os.tag == .emscripten)
    std.heap.c_allocator
else
    std.heap.page_allocator;

const CANVAS_WIDTH: c_int = 320;
const CANVAS_HEIGHT: c_int = 240;

pub fn appInit(_: ?*?*anyopaque, _: [][*:0]u8) !sdl.SDL_AppResult {
    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
        return sdl.SDL_APP_FAILURE;
    }

    _ = sdl.SDL_CreateWindowAndRenderer(
        "wrum",
        1280,
        720,
        0,
        @ptrCast(&window),
        @ptrCast(&renderer),
    );

    canvas = sdl.SDL_CreateTexture(
        renderer,
        sdl.SDL_PIXELFORMAT_RGBA8888,
        sdl.SDL_TEXTUREACCESS_TARGET,
        320,
        240,
    );

    _ = sdl.SDL_SetTextureScaleMode(canvas, sdl.SDL_SCALEMODE_NEAREST);
    _ = sdl.SDL_SetTextureBlendMode(canvas, sdl.SDL_BLENDMODE_NONE);

    last = sdl.SDL_GetPerformanceCounter();

    s = try stack.Stack.init(allocator, renderer, "assets/cars", 6);

    return sdl.SDL_APP_CONTINUE;
}

pub fn appIterate(_: ?*anyopaque) !sdl.SDL_AppResult {
    const now = sdl.SDL_GetPerformanceCounter();
    const dt =
        @as(f32, @floatFromInt(now - last)) /
        @as(f32, @floatFromInt(sdl.SDL_GetPerformanceFrequency()));
    last = now;

    rotation += 45 * dt;

    _ = sdl.SDL_SetRenderTarget(renderer, canvas);
    _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    _ = sdl.SDL_RenderClear(renderer);

    s.draw(renderer, [2]f32{ 100, 100 }, rotation);

    _ = sdl.SDL_SetRenderTarget(renderer, null);
    _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    _ = sdl.SDL_RenderClear(renderer);

    var w: c_int = undefined;
    var h: c_int = undefined;
    _ = sdl.SDL_GetWindowSize(window, &w, &h);

    const scale = @min(@as(f32, @floatFromInt(w)) / CANVAS_WIDTH, @as(f32, @floatFromInt(h)) / CANVAS_HEIGHT);

    const dst_w = CANVAS_WIDTH * scale;
    const dst_h = CANVAS_HEIGHT * scale;

    const x = (@as(f32, @floatFromInt(w)) - dst_w) / 2.0;
    const y = (@as(f32, @floatFromInt(h)) - dst_h) / 2.0;

    const dst_rect = sdl.SDL_FRect{
        .x = x,
        .y = y,
        .w = dst_w,
        .h = dst_h,
    };

    _ = sdl.SDL_RenderTexture(renderer, canvas, null, &dst_rect);
    _ = sdl.SDL_RenderPresent(renderer);

    return sdl.SDL_APP_CONTINUE;
}

pub fn appEvent(_: ?*anyopaque, event: *sdl.SDL_Event) !sdl.SDL_AppResult {
    if (event.type == sdl.SDL_EVENT_QUIT) {
        return sdl.SDL_APP_SUCCESS;
    }
    return sdl.SDL_APP_CONTINUE;
}

pub fn appQuit(_: ?*anyopaque, _: anyerror!sdl.SDL_AppResult) void {
    s.deinit(allocator);

    sdl.SDL_DestroyTexture(canvas);
    sdl.SDL_DestroyRenderer(renderer);
    sdl.SDL_DestroyWindow(window);
    sdl.SDL_Quit();
}
