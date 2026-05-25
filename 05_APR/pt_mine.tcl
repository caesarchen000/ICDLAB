# PrimeTime PX — lab slide style (timing + power)
# Run: pt_shell -f pt_mine.tcl | tee pt_mine.log

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
    puts "ERROR: link failed — check ./Verilog/*.db"
    report_link
    exit 1
}

set_operating_conditions -max WCCOM -max_library fsa0m_a_generic_core_ss1p62v125c \
                         -min BCCOM -min_library fsa0m_a_generic_core_ff1p98vm40c

# Innovus write_sdc: strip "current_design CHIP" before read_sdc
set fin [open ./CHIP_postAPR.sdc r]
set fout [open ./CHIP_postAPR.pt.sdc w]
while {[gets $fin line] >= 0} {
    if {[regexp {^current_design} $line]} { continue }
    puts $fout $line
}
close $fin
close $fout

read_sdc ./CHIP_postAPR.pt.sdc
read_sdf -load_delay net ./CHIP.sdf

# VCD from posim: scope must match tb hierarchy (not "CHIP")
read_vcd -strip_path tb/u_chip ./CHIP_post.vcd

update_timing
update_power

report_power > CHIP_power_report_apr_sdc.rpt
report_timing -delay_type max -max_paths 10 -slack_lesser_than 999 -nosplit > CHIP_setup_timing_apr_sdc.rpt
report_timing -delay_type min -max_paths 10 -slack_lesser_than 999 -nosplit > CHIP_hold_timing_apr_sdc.rpt
report_constraint -all_violators -nosplit > CHIP_constraint_pt.rpt

set wns [get_attribute [get_timing_paths -max_paths 1 -nworst 1 -delay_type max] slack]
puts "\n=========================================="
puts " WORST SETUP SLACK (WNS) = $wns ns"
puts "=========================================="

exit
