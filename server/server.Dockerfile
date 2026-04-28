FROM alpine:3.19

RUN apk add --no-cache zig

WORKDIR /app
COPY . .

RUN zig build -Doptimize=ReleaseSafe

CMD ["./zig-out/bin/server"]