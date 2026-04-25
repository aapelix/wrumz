#!/bin/bash
set -e

cd zig-out/www
python3 -m http.server 8021 & open http://localhost:8021
