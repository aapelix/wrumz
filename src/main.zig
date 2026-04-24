const sdl = @import("sdl.zig").c;
const app = @import("app.zig");

pub fn main() !u8 {
    var argv: [0:null]?[*:0]u8 = .{};

    return @truncate(@as(c_uint, @bitCast(
        sdl.SDL_RunApp(argv.len, @ptrCast(&argv), sdlMain, null),
    )));
}

fn sdlMain(argc: c_int, argv: ?[*:null]?[*:0]u8) callconv(.c) c_int {
    return sdl.SDL_EnterAppMainCallbacks(
        argc,
        @ptrCast(argv),
        appInitC,
        appIterateC,
        appEventC,
        appQuitC,
    );
}

fn appInitC(appstate: ?*?*anyopaque, argc: c_int, argv: ?[*:null]?[*:0]u8) callconv(.c) sdl.SDL_AppResult {
    return app.appInit(appstate.?, @ptrCast(argv.?[0..@intCast(argc)])) catch sdl.SDL_APP_ERROR;
}

fn appIterateC(appstate: ?*anyopaque) callconv(.c) sdl.SDL_AppResult {
    return app.appIterate(appstate) catch sdl.SDL_APP_ERROR;
}

fn appEventC(appstate: ?*anyopaque, event: ?*sdl.SDL_Event) callconv(.c) sdl.SDL_AppResult {
    return app.appEvent(appstate, event.?) catch sdl.SDL_APP_ERROR;
}

fn appQuitC(appstate: ?*anyopaque, result: sdl.SDL_AppResult) callconv(.c) void {
    app.appQuit(appstate, result);
}
