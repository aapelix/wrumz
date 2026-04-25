#!/bin/bash
set -e

zig build -Dtarget=wasm32-emscripten --sysroot "$(em-config CACHE)/sysroot"
cp index.html zig-out/www/index.html
