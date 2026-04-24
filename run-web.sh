#!/bin/bash
set -e

cd zig-out/www
python3 -m http.server & open http://localhost:8000
