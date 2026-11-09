#!/bin/bash
# Rebuilds the whole world the way the committed data was made:
#   1. build_world.rb (maps, events, tilesets, PBS, 091_World_Generated.rb)
#   2. t_compile.rb (PBS + plugins), keeping the built Tilesets.rxdata
#   3. t_reach.rb SEAL=1 from the forest: the small pockets nothing reaches get
#      an invisible solid tile (invisible.rb). Skip with NOSEAL=1.
# The audit's map list is every map in world_ids.json's regions plus the map
# pack maps they use: tools/headless/all_ids.txt (one comma-separated line).
#   tools/headless/rebuild.sh
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
cd "$ROOT"
LOG="${LOG_DIR:-/tmp}/fullpoke_rebuild"
mkdir -p "$LOG"
tools/headless/run.sh build_world.rb > "$LOG/build.log" 2>&1 || true
if grep -qE "^/tools/.*rb:[0-9]+:in" "$LOG/build.log"; then
  grep -B2 -A6 -m1 "rb:[0-9]*:in" "$LOG/build.log"; exit 1
fi
grep -E "^WARNING" "$LOG/build.log" | grep -vE "placed without|opens onto|lines up only" || true
cp Data/Tilesets.rxdata "$LOG/Tilesets_built.rxdata"
tools/headless/run.sh t_compile.rb > "$LOG/compile.log" 2>&1 || true
tail -1 "$LOG/compile.log"
cp "$LOG/Tilesets_built.rxdata" Data/Tilesets.rxdata
git checkout Data/PkmnAnimations.rxdata 2>/dev/null || true
if [ -z "$NOSEAL" ]; then
  [ -f "$HERE/all_ids.txt" ] || { echo "tools/headless/all_ids.txt missing (map ids for the audit)"; exit 1; }
  SEAL=1 SURF=1 AUDIT=@all_ids.txt tools/headless/run.sh t_reach.rb 913 2 73 > "$LOG/seal.log" 2>&1
  grep -E "AUDIT total|SEALED|rb:[0-9]+:in" "$LOG/seal.log"
fi
