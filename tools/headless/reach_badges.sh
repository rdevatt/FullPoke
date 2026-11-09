#!/bin/bash
# Rule-aware reachability for each badge count:
#   tools/headless/reach_badges.sh <region> <start map> <x> <y> <surf from badges> <target maps...>
HERE="$(cd "$(dirname "$0")" && pwd)"
region=$1; m=$2; x=$3; y=$4; surf=$5; shift 5
for k in 0 1 2 3 4 5 6 7 8; do
  s=0; [ "$k" -ge "$surf" ] && s=1
  printf "%s badges: " "$k"
  RULES=$region:$k SURF=$s "$HERE/run.sh" t_reach.rb "$m" "$x" "$y" "$@" 2>&1 | grep -E "^  (OK|NO)" | awk '{printf "%s %s | ", $1, $3$4}'
  echo
done
