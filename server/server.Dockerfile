FROM alpine:3.19

RUN apk add --no-cache curl tar \
 && curl -L https://ziglang.org/download/0.15.2/zig-x86_64-linux-0.15.2.tar.xz \
 | tar -xJ \
 && mv zig-x86_64-linux-0.15.2 /zig

ENV PATH="/zig:$PATH"

WORKDIR /app
COPY msg ./msg
COPY server ./server
WORKDIR /app/server

RUN zig build -Doptimize=ReleaseSafe

CMD ["./zig-out/bin/server"]