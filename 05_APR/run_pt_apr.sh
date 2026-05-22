#!/bin/bash
# PrimeTime PX: post-APR power/timing with SDF + VCD
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f CHIP_post.vcd ]]; then
  echo "CHIP_post.vcd missing — run: ./run_postsim_vcd.sh"
  exit 1
fi

pt_shell -f pt_script_apr_sdc.tcl | tee pt_apr_sdc.log
