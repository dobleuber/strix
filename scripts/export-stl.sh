#!/usr/bin/env bash
# Export every printable part of cad/strix-print.scad to stl/ in its print pose.
# Usage: scripts/export-stl.sh [part ...]     (no arguments = all parts)
set -euo pipefail
cd "$(dirname "$0")/.."
PARTS=(plate shell deck cap ring turntable retainer arm_servo arm_idle cover_servo cover_idle turntable_cover
       head_rear head_front trunnion iris bezel sled spacer port_plug gauge)
[ $# -gt 0 ] && PARTS=("$@")
mkdir -p stl
for p in "${PARTS[@]}"; do
    echo "== $p"
    openscad cad/strix-print.scad -o "stl/$p.stl" --export-format binstl -D "part=\"$p\"" 2>&1 \
        | grep -E "Simple|Vertices|ERROR|WARNING" || true
done
