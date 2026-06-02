# PrimeTime STA — post-APR (lab flow: CHIP.v + CHIP.sdf + CHIP_postAPR.sdc)
# Before PT, in Innovus on finished design:  write_sdc CHIP_postAPR.sdc
# Setup:  source /usr/cad/synopsys/CIC/primetime.cshrc
# Run from 05_APR:  pt_shell -f pt_script.tcl | tee pt_sta.log

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

set_operating_conditions -max WCCOM -max_library fsa0m_a_generic_core_ss1p62v125c \
                         -min BCCOM -min_library fsa0m_a_generic_core_ff1p98vm40c

# Innovus write_sdc includes "current_design CHIP" — invalid in PT read_sdc
set fin [open ./CHIP_postAPR.sdc r]
set fout [open ./CHIP_postAPR.pt.sdc w]
while {[gets $fin line] >= 0} {
  # Innovus-only / DC-only commands not valid in PrimeTime read_sdc
    if {[regexp {^current_design} $line]} { continue }
    if {[regexp {get_designs} $line]} { continue }
    puts $fout $line
}
close $fin
close $fout

set sdc_ok [catch {read_sdc ./CHIP_postAPR.pt.sdc} sdc_err]
if {$sdc_ok != 0} {
    puts "WARN: CHIP_postAPR.pt.sdc failed ($sdc_err); using design/CHIP.sdc"
    read_sdc ./design/CHIP.sdc
}

read_sdf -load_delay net ./CHIP.sdf
update_timing

report_timing -delay_type max -max_paths 10 -slack_lesser_than 999 -nosplit > CHIP_setup_timing_pt.rpt
report_timing -delay_type min -max_paths 10 -slack_lesser_than 999 -nosplit > CHIP_hold_timing_pt.rpt
report_constraint -all_violators -nosplit > CHIP_constraint_pt.rpt
report_qor > CHIP_qor_pt.rpt

set wns [get_attribute [get_timing_paths -max_paths 1 -nworst 1 -delay_type max] slack]
if {$wns == ""} { set wns "N/A (no constrained paths — SDC/clock problem)" }
set fh [open CHIP_timing_summary.txt w]
puts $fh "Post-APR PrimeTime STA summary"
puts $fh "Worst setup slack (WNS): $wns ns"
puts $fh "Clock period: 11 ns"
if {$wns != "N/A (no constrained paths — SDC/clock problem)" && $wns < 0} {
    puts $fh "Setup timing: VIOLATED"
} elseif {$wns != "N/A (no constrained paths — SDC/clock problem)"} {
    puts $fh "Setup timing: MET"
}
close $fh

puts "\n=========================================="
puts " WORST SETUP SLACK (WNS) = $wns ns"
if {$wns != "N/A (no constrained paths — SDC/clock problem)" && $wns < 0} {
    puts " SETUP TIMING: VIOLATED (see CHIP_setup_timing_pt.rpt)"
} elseif {$wns != "N/A (no constrained paths — SDC/clock problem)"} {
    puts " SETUP TIMING: MET"
}
puts "=========================================="
report_timing -delay_type max -max_paths 1 -nworst 1 -nosplit

puts "\nReports: CHIP_timing_summary.txt CHIP_setup_timing_pt.rpt CHIP_constraint_pt.rpt CHIP_qor_pt.rpt"
exit
