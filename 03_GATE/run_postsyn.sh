#!/bin/bash
# Post-synthesis gate simulation (CHIP_syn.v + CHIP_syn.sdf)
# Run on cad16 after: cd 02_SYN && dc_shell -f CHIP_syn.tcl
set -e
cd "$(dirname "$0")"

if [[ -d /usr/cad/synopsys/vcs/2022.06/linux64/bin ]]; then
  export VCS_HOME=/usr/cad/synopsys/vcs/2022.06
  export PATH="$VCS_HOME/linux64/bin:$PATH"
fi

LIB="../05_APR/Verilog/fsa0m_a_generic_core_21.lib.src"
SDF="../02_SYN/Netlist/CHIP_syn.sdf"
NL="../02_SYN/Netlist/CHIP_syn.v"

for f in "$LIB" "$SDF" "$NL" ../00_TESTBED/pattern/input.txt ../00_TESTBED/pattern/golden.txt; do
  if [[ ! -f $f ]]; then
    echo "ERROR: missing $f"
    exit 1
  fi
done

VCS_BASE=(../00_TESTBED/testbench/tb.v -f gate.f "$LIB" -full64 -R +v2k +neg_tchk -debug_access+all)

run_step() {
  local n=$1 msg=$2
  shift 2
  echo "=== ($n) $msg ==="
  vcs "${VCS_BASE[@]}" "$@"
  echo "($n) done."
}

# Usage: bash run_postsyn.sh        # both steps
#        bash run_postsyn.sh 1     # functional only (recommended before APR)
#        bash run_postsyn.sh 2     # SDF smoke only
STEP="${1:-all}"

case "$STEP" in
  1)
    run_step 1 "Functional gate (no SDF)"
    ;;
  2)
    run_step 2 "Gate + SDF (+notimingcheck)" +define+SDF +notimingcheck
    ;;
  all|*)
    run_step 1 "Functional gate (no SDF) — APR handoff check"
    echo ""
    run_step 2 "Gate + SDF smoke" +define+SDF +notimingcheck
    ;;
esac

echo ""
echo "Pass step 1 if: no '抓到了', low MSE, no 'Time out'."
