#!/bin/bash
# Renders a map to PNG for inspection (needs the chunky_png image, built once with
#   docker build -t fullpoke-ruby tools/headless/docker).
#   tools/headless/render.sh <map id> [x y w h] [pixels per tile]
#   PASS=1 tools/headless/render.sh 175 5 4 17 17 32   # overlay blocked/counter tiles
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
mkdir -p "$HERE/renders"
docker run --rm -e PASS="${PASS:-0}" -v "$ROOT":/game:ro -v "$HERE":/tools fullpoke-ruby \
  ruby /tools/render_map.rb /game "$1" "/tools/renders/map$1${2:+_$2_$3}.png" "${@:2}"
