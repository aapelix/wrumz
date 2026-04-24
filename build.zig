const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const is_wasm = target.result.os.tag == .emscripten;

    if (is_wasm) {
        buildWasm(b, target, optimize);
        return;
    }

    const exe = b.addExecutable(.{
        .name = "wrumz",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const sdl_dep = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
    });
    const sdl_lib = sdl_dep.artifact("SDL3");

    exe.root_module.linkLibrary(sdl_lib);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}

pub fn buildWasm(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "wrumz",
        .root_module = mod,
    });

    if (b.sysroot) |sysroot| {
        mod.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ sysroot, "include" }) });
        b.sysroot = sysroot;
    }

    const lto: ?std.zig.LtoMode = if (optimize != .Debug) .full else null;

    const sdl_dep = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
        .lto = lto,
    });

    const sdl_lib = sdl_dep.artifact("SDL3");
    mod.linkLibrary(sdl_lib);

    const run_emcc = b.addSystemCommand(&.{"emcc"});

    for (lib.getCompileDependencies(false)) |l| {
        if (l.isStaticLibrary()) {
            run_emcc.addArtifactArg(l);
        }
    }

    if (target.result.cpu.arch == .wasm64) {
        run_emcc.addArg("-sMEMORY64");
    }

    run_emcc.addArgs(switch (optimize) {
        .Debug => &.{
            "-O0",
            // Preserve DWARF debug information.
            "-g",
            // Use UBSan (full runtime).
            "-fsanitize=undefined",
        },
        .ReleaseSafe => &.{
            "-O3",
            // Use UBSan (minimal runtime).
            "-fsanitize=undefined",
            "-fsanitize-minimal-runtime",
        },
        .ReleaseFast => &.{
            "-O3",
        },
        .ReleaseSmall => &.{
            "-Oz",
        },
    });

    if (optimize != .Debug) {
        run_emcc.addArg("-flto");
        run_emcc.addArgs(&.{ "--closure", "1" });
    }

    run_emcc.addArg("--pre-js");
    run_emcc.addFileArg(b.addWriteFiles().add("pre.js", (
        \\Module['printErr'] ??= Module['print'];
    )));

    run_emcc.addArg("-o");
    const app_js = run_emcc.addOutputFileArg("wrumz.js");

    b.getInstallStep().dependOn(&b.addInstallDirectory(.{
        .source_dir = app_js.dirname(),
        .install_dir = .{ .custom = "www" },
        .install_subdir = "",
    }).step);

    const run_emrun = b.addSystemCommand(&.{"emrun"});
    run_emrun.addArg(b.pathJoin(&.{ b.install_path, "www", "wrumz.js" }));
    if (b.args) |args| run_emrun.addArgs(args);
    run_emrun.step.dependOn(b.getInstallStep());

    const run = b.step("run", "Run the app");
    run.dependOn(&run_emrun.step);
}
