# Remove all BONDPADD_m instances (BPad_*). Safe when none exist.
set bpads [dbGet top.insts.name BPad* -u]

if {$bpads eq "" || $bpads eq "0x0"} {
    puts "INFO: No BPad_* instances in design (already clean)."
} else {
    foreach inst $bpads {
        puts "deleteInst $inst"
        deleteInst $inst
    }
    puts "INFO: Deleted [llength $bpads] bond pad(s)."
}

redraw
