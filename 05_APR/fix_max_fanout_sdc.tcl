# Clear stale set_max_fanout [current_design] from MMMC (flags CTS clock pins after clockDesign).
# Run from 05_APR:
#   source fix_max_fanout_sdc.tcl
#
# design/CHIP.sdc must have no set_max_fanout lines.

set sdc_file design/CHIP.sdc

puts "=== Reload clean CHIP.sdc ==="
update_constraint_mode -name func_mode -sdc_files $sdc_file
update_constraint_mode -name scan_mode -sdc_files $sdc_file

puts "=== Clear global max_fanout in func_mode ==="
set_interactive_constraint_modes func_mode
reset_max_fanout [current_design]
set_interactive_constraint_modes { }

puts "=== max_fanout violations ==="
report_constraint -drv_violation_type max_fanout

puts "=== Done. CTS_ccl_a_INV_CLK_* should be gone. ==="
puts "Data fanout (if any): source fix_max_fanout.tcl"
