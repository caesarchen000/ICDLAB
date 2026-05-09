sh mkdir -p Netlist
sh mkdir -p Report

# Read Design
set fp [open "../01_RTL/rtl.f" r]
set file_content [read $fp]
close $fp

# 使用 split 將換行符號切割，並過濾掉可能的空白行
set files ""
foreach line [split $file_content "\n"] {
    set clean_line [string trim $line]
    if {$clean_line != ""} {
        lappend files $clean_line
    }
}

read_file -format verilog $files

set DESIGN "CHIP"
current_design [get_designs $DESIGN]
uniquify
link

#You may modified the clock constraints 
#or add more constraints for your design
####################################################
set cycle  20
####################################################

#The following are design spec. for synthesis
#You can NOT modify this seciton 
#####################################################
create_clock -name CLK -period $cycle [get_ports clk]
set_fix_hold                          [get_clocks CLK]
set_dont_touch_network                [get_clocks CLK]
# set_ideal_network                     [get_ports clk]
# set_ideal_network                     [get_ports rst_n]

set_clock_uncertainty 0.1  [get_clocks CLK]
set_clock_latency     0.5  [get_clocks CLK]
set_input_delay  -max 1   -clock CLK [all_inputs]
set_output_delay -min 0.5 -clock CLK [all_outputs]
set_drive 1  [all_inputs]
# set_load  10 [all_outputs]

set_fix_multiple_port_nets -all -buffer_constants

set_operating_conditions -min_library fsa0m_a_generic_core_ff1p98vm40c -min BCCOM -max_library fsa0m_a_generic_core_ss1p62v125c -max WCCOM
set_wire_load_model -name G200K -library fsa0m_a_generic_core_tt1p8v25c

set_max_area 0
set_max_fanout 6 [get_designs $DESIGN]
set_boundary_optimization {"*"}
check_design

#####################################################
#Compile and save files
set_host_options -max_cores 16
set_max_area 0

compile -area_effort high
# optimize_netlist -area
# compile_ultra -inc -retime

#####################################################
report_area         -hierarchy              > ./Report/${DESIGN}_syn.area
report_timing       -delay min  -max_path 5 > ./Report/${DESIGN}_syn.timing_min
report_timing       -delay max  -max_path 5 > ./Report/${DESIGN}_syn.timing_max

write   -f ddc      -hierarchy  -output ./Netlist/${DESIGN}_syn.ddc
write   -f verilog  -hierarchy  -output ./Netlist/${DESIGN}_syn.v
write_sdf   -version 2.1                ./Netlist/${DESIGN}_syn.sdf
write_sdc   -version 1.8                ./Netlist/${DESIGN}_syn.sdc