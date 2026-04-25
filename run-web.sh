#!/bin/bash
set -e

cd zig-out/www
python3 -m http.server 6021 &
PID=$!

open http://localhost:6021

trap "kill $PID" EXIT
wait $PID
