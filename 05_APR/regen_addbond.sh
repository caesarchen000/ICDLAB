#!/bin/bash
# Regenerate addbond.cmd / CHIP.bondinfo from the current placed DEF.
# Run in 05_APR after defOut (floorplan + IO placed), before sourcing addbond.cmd in Innovus.
set -e
cd "$(dirname "$0")"
DEF="${1:-CHIP.def}"
perl addbonding_v3.8D.pl "$DEF" -io io_D.list
echo "Wrote addbond.cmd and CHIP.bondinfo from $DEF"
