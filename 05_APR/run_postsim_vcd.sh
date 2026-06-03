#!/bin/bash
# Post-APR gate sim (CHIP.v + CHIP.sdf). Run from 05_APR on cad16.
set -e
cd "$(dirname "$0")"

if [[ -d /usr/cad/synopsys/vcs/2022.06/linux64/bin ]]; then
  export VCS_HOME=/usr/cad/synopsys/vcs/2022.06
  export PATH="$VCS_HOME/linux64/bin:$PATH"
fi

for f in tb.v CHIP.v CHIP.sdf Verilog/fsa0m_a_generic_core_21.lib.src \
         Verilog/fsa0m_a_t33_generic_io_21.lib.src \
         ../00_TESTBED/pattern/input.txt ../00_TESTBED/pattern/golden.txt; do
  [[ -f $f ]] || { echo "ERROR: missing $f"; exit 1; }
done

# Stale csrc/simv.daidir causes: assertion procJsonFile (CgFlow.cc) — always clean before APR netlist compile
rm -rf csrc simv simv.daidir AN.DB urgReport vc_hdrs.h ucli.key DVEfiles inter.vpd

echo "=== Post-APR gate + SDF + VCD ==="
vcs tb.v CHIP.v \
  -v Verilog/fsa0m_a_generic_core_21.lib.src Verilog/fsa0m_a_t33_generic_io_21.lib.src \
  -full64 -R +v2k +neg_tchk \
  +define+SDF +define+VCD +notimingcheck \
  -l postsim.log

echo "Done. Check postsim.log for MSE."
echo "VCD: $(pwd)/CHIP_post.vcd"
ls -la CHIP_post.vcd 2>/dev/null || true
