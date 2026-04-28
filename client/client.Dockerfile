FROM nginx:alpine

COPY zig-out/www /usr/share/nginx/html

EXPOSE 80