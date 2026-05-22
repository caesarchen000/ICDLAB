# Fix SDC max_fanout (fanout *count*) violations — match lab Innovus flow.
# Run in Innovus after place / first optDesign (DB must be loaded).
#
#   cd ~/chip_v2/05_APR
#   read_sdc design/CHIP.sdc
#   source fix_max_fanout.tcl

puts "=== max_fanout BEFORE ==="
catch { report_constraint -all_violators -max_fanout }

# Lab flow (see innovus log): fixFanoutLoad + full preCTS GigaOpt fixes fanout count
setOptMode -fixCap true -fixTran true -fixFanoutLoad true

puts "=== optDesign -preCTS (DRV + high-fanout net opt) ==="
optDesign -preCTS

puts "=== max_fanout AFTER pass 1 ==="
set v1 1
catch { report_constraint -all_violators -max_fanout } r
if {[string match *"No constraint violators"* $r] || [string match *"0 violat*" $r]} { set v1 0 }

if {$v1} {
  puts "=== second pass: optDesign -preCTS -incremental ==="
  optDesign -preCTS -incremental
  puts "=== max_fanout AFTER pass 2 ==="
  catch { report_constraint -all_violators -max_fanout }
}

puts ""
puts "=== Timing check ==="
report_timing_summary

puts ""
puts "If max_fanout is clean: saveDesign DBS/preCTS_fanout_fixed"
puts "Then: clockDesign -> optDesign -postCTS -> routeDesign"
