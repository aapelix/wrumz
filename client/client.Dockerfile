FROM emscripten/emsdk:latest AS builder

RUN apt-get update && apt-get install -y curl xz-utils \
 && curl -L https://ziglang.org/download/0.15.2/zig-x86_64-linux-0.15.2.tar.xz \
 | tar -xJ \
 && mv zig-linux-* /opt/zig
ENV PATH="/opt/zig:${PATH}"

WORKDIR /app
COPY client ./client
WORKDIR /app/client

RUN embuilder build sdl3

RUN zig build -Dtarget=wasm32-emscripten -Doptimize=ReleaseFast \
    --sysroot "$(em-config CACHE)/sysroot"

RUN cp index.html zig-out/www/index.html

FROM nginx:alpine
COPY --from=builder /app/client/zig-out/www /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]