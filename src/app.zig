const sdl = @import("sdl.zig").c;

var window: *sdl.SDL_Window = undefined;
var renderer: *sdl.SDL_Renderer = undefined;

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

    return sdl.SDL_APP_CONTINUE;
}

pub fn appIterate(_: ?*anyopaque) !sdl.SDL_AppResult {
    _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    _ = sdl.SDL_RenderClear(renderer);

    _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
    const rect = sdl.SDL_FRect{
        .x = 100,
        .y = 100,
        .w = 200,
        .h = 150,
    };
    _ = sdl.SDL_RenderFillRect(renderer, &rect);

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
    sdl.SDL_DestroyRenderer(renderer);
    sdl.SDL_DestroyWindow(window);
    sdl.SDL_Quit();
}
