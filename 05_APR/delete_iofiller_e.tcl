# Delete east IO fillers one-by-one (Innovus deleteInst does not take a list).
set fillers [dbGet top.insts.name IOFILLER_E* -u]

if {$fillers eq "" || $fillers eq "0x0"} {
    puts "INFO: No IOFILLER_E_* instances in design."
} else {
    set n 0
    foreach inst $fillers {
        if {[catch {deleteInst $inst} err]} {
            puts "WARN: deleteInst $inst failed: $err"
        } else {
            incr n
        }
    }
    puts "INFO: Deleted $n IOFILLER_E_* instance(s)."
}

redraw
