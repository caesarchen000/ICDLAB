# ==========================================================================
# PrimeTime PX (Power Analysis) — post-APR netlist + SDF + VCD
# Run from 05_APR:  pt_shell -f pt_script_apr_sdc.tcl | tee pt_apr_sdc.log
# Libraries: .db in ./Verilog (DC-compiled; PT has read_db, not read_liberty)
# ==========================================================================

set power_enable_analysis TRUE
set power_analysis_mode time_based

set search_path [list "./" "./Verilog" "./lib"]

set link_library [list "*" \
    fsa0m_a_generic_core_tt1p8v25c.db \
    fsa0m_a_generic_core_ss1p62v125c.db \
    fsa0m_a_generic_core_ff1p98vm40c.db \
    fsa0m_a_t33_generic_io_tt1p8v25c.db \
    fsa0m_a_t33_generic_io_ss1p62v125c.db \
    fsa0m_a_t33_generic_io_ff1p98vm40c.db]

read_verilog ./CHIP.v
current_design CHIP

if {![link]} {
    puts "ERROR: link failed — check ./Verilog/*.db and CHIP.v"
    report_link
    exit 1
}

# SDF min::max corners (WCCOM=ss, BCCOM=ff) per lib headers
set_operating_conditions -max WCCOM -max_library fsa0m_a_generic_core_ss1p62v125c \
                         -min BCCOM -min_library fsa0m_a_generic_core_ff1p98vm40c

read_sdc ./design/CHIP.sdc

read_sdf -load_delay net ./CHIP.sdf

# VCD: ./run_postsim_vcd.sh  (+define+VCD → CHIP_post.vcd, scope tb/u_chip)
read_vcd -strip_path tb/u_chip ./CHIP_post.vcd

update_timing
update_power

report_power > CHIP_power_report_apr_sdc.rpt
report_timing -delay_type max -max_paths 10 -slack_lesser_than 999 -nosplit > CHIP_setup_timing_apr_sdc.rpt
report_timing -delay_type min -max_paths 10 -slack_lesser_than 999 -nosplit > CHIP_hold_timing_apr_sdc.rpt

exit
