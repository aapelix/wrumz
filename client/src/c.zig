pub const c = @cImport({
    if (@import("builtin").os.tag != .emscripten) {
        @cInclude("libwebsockets.h");
    }

    @cDefine("SDL_MAIN_HANDLED", {});
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3/SDL_main.h");
});
