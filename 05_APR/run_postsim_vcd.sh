#!/bin/bash
# Post-layout gate sim + IEEE VCD for PrimeTime PX (run from 05_APR)
set -e
cd "$(dirname "$0")"

vcs tb.v CHIP.v \
  Verilog/fsa0m_a_generic_core_21.lib.src \
  Verilog/fsa0m_a_io_pad_only.lib.src \
  -full64 -R \
  -debug_access+all \
  +v2k +neg_tchk +define+SDF +define+VCD

echo "VCD: $(pwd)/CHIP_post.vcd"
ls -la CHIP_post.vcd
