#!/bin/bash
# Run RGB channel RTL sim (one channel per invocation).
set -e
cd "$(dirname "$0")"
VCS_OPTS="../00_TESTBED/testbench/tb_2d_rgb.v -f rtl.f -full64 -R +v2k -debug_access+all"
for CH in CH_R CH_G CH_B; do
  echo "=== $CH ==="
  vcs $VCS_OPTS +define+$CH
done
echo "Done. Run: cd ../00_TESTBED/gen && python3 rtl_rgb_flow.py merge"
