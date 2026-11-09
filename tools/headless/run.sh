#!/bin/bash
# Runs a headless task against this repo with the game's own Scripts.rxdata.
#   tools/headless/run.sh t_compile.rb          # compile PBS like Debug mode does
#   tools/headless/run.sh t_journey.rb          # play new game -> Boulder Badge
#   HEADLESS_DEBUG=0 tools/headless/run.sh t_release.rb   # boot like a player's launch
# Needs Docker (or set RUBY=ruby to use a local Ruby 3.1).
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
if [ -n "$RUBY" ]; then
  cd "$HERE" && GAME_DIR="$ROOT" HEADLESS_SAVE_DIR="${HEADLESS_SAVE_DIR:-/tmp/fullpoke_saves}" "$RUBY" boot.rb "$@"
else
  docker run --rm -e GAME_DIR=/game -e HEADLESS_DEBUG="${HEADLESS_DEBUG:-1}" -e REGIONS -e MODE -e VERBOSE -e SURF -e ORDER -e GRID -e RULES -e PRIOR \
    -e HEADLESS_SAVE_DIR=/tmp/fullpoke_saves -v "$ROOT":/game -v "$HERE":/tools -w /tools \
    "${FULLPOKE_RUBY_IMAGE:-ruby:3.1-slim}" ruby /tools/boot.rb "$@"
fi
