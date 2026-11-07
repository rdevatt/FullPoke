#!/bin/bash
# Runs a standalone data tool (no game scripts) against this repo's Data folder, e.g.
#   tools/headless/rb.sh dump_events.rb /game/Data 23      # list Pallet Town's events
#   tools/headless/rb.sh warps.rb /game/Data 173            # list Viridian's warps
#   tools/headless/rb.sh warp_pairs.rb /game/Data           # report unpaired warps
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
docker run --rm -e APPLY="${APPLY:-0}" -v "$ROOT":/game -v "$HERE":/tools -w /tools \
  "${FULLPOKE_RUBY_IMAGE:-ruby:3.1-slim}" ruby "/tools/$1" "${@:2}"
