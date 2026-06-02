#!/bin/bash
# RGB flow with 11-bit inter-pass storage (CHIP IOPORT_IN_W=22)
set -e
cd "$(dirname "$0")"
VCS_OPTS="../00_TESTBED/testbench/tb_2d_rgb_11.v -f rtl.f -full64 -R +v2k -debug_access+all"
for CH in CH_R CH_G CH_B; do
  echo "=== $CH (11-bit in) ==="
  vcs $VCS_OPTS +define+$CH
done
echo "Done. cd ../00_TESTBED/gen && python3 rtl_rgb_flow.py merge --in11"
