###################################################################
# Innovus APR (mmmc.view → design/CHIP.sdc)
# Source: CHIP_syn.sdc + minimal Innovus edits (see CHIP_previous.sdc)
# Regenerate: python3 mk_apr_sdc.py [CHIP_syn.sdc]
###################################################################


set sdc_version 1.8

# Innovus: set_units / set_max_area unsupported (CTE-25). MMMC owns corners.
# set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
# set_operating_conditions -max WCCOM -max_library fsa0m_a_generic_core_ss1p62v125c \
#                          -min BCCOM -min_library fsa0m_a_generic_core_ff1p98vm40c

# Innovus MMMC: wire_load from RC corners, not SDC wire_load_model
# set_wire_load_model -name G200K -library fsa0m_a_generic_core_tt1p8v25c
# Innovus: no set_max_fanout in SDC after CTS — [current_design] flags clock nets (fanout 40+);
# [all_outputs]/[all_registers] are invalid or fail TCLCMD-1117/917 on CHIP+pad netlist.
# Data fanout DRV: setOptMode -fixFanoutLoad + optDesign (see fix_max_fanout.tcl).
# DC syn only: set_max_fanout 32 [current_design] in 02_SYN/Netlist/CHIP_syn.sdc
# set_max_area 0
set_load -pin_load 1 [get_ports i_ready]
set_load -pin_load 1 [get_ports o_valid]
set_load -pin_load 1 [get_ports {o_data[10]}]
set_load -pin_load 1 [get_ports {o_data[9]}]
set_load -pin_load 1 [get_ports {o_data[8]}]
set_load -pin_load 1 [get_ports {o_data[7]}]
set_load -pin_load 1 [get_ports {o_data[6]}]
set_load -pin_load 1 [get_ports {o_data[5]}]
set_load -pin_load 1 [get_ports {o_data[4]}]
set_load -pin_load 1 [get_ports {o_data[3]}]
set_load -pin_load 1 [get_ports {o_data[2]}]
set_load -pin_load 1 [get_ports {o_data[1]}]
set_load -pin_load 1 [get_ports {o_data[0]}]
create_clock [get_ports clk]  -name CLK  -period 10  -waveform {0 5}
set_clock_latency 0.5  [get_clocks CLK]
set_clock_uncertainty 0.1  [get_clocks CLK]
# Innovus: no set_input_delay on clock root (TCLNL-330)
# set_input_delay -clock CLK  -max 1  [get_ports clk]
set_input_delay -clock CLK  -max 1  [get_ports rst_n]
set_input_delay -clock CLK  -max 1  [get_ports i_valid]
set_input_delay -clock CLK  -max 1  [get_ports o_ready]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[15]}]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[14]}]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[13]}]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[12]}]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[11]}]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[10]}]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[9]}]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[8]}]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[7]}]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[6]}]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[5]}]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[4]}]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[3]}]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[2]}]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[1]}]
set_input_delay -clock CLK  -max 1  [get_ports {i_data[0]}]
set_output_delay -clock CLK  -min 0.5  [get_ports i_ready]
set_output_delay -clock CLK  -min 0.5  [get_ports o_valid]
set_output_delay -clock CLK  -min 0.5  [get_ports {o_data[10]}]
set_output_delay -clock CLK  -min 0.5  [get_ports {o_data[9]}]
set_output_delay -clock CLK  -min 0.5  [get_ports {o_data[8]}]
set_output_delay -clock CLK  -min 0.5  [get_ports {o_data[7]}]
set_output_delay -clock CLK  -min 0.5  [get_ports {o_data[6]}]
set_output_delay -clock CLK  -min 0.5  [get_ports {o_data[5]}]
set_output_delay -clock CLK  -min 0.5  [get_ports {o_data[4]}]
set_output_delay -clock CLK  -min 0.5  [get_ports {o_data[3]}]
set_output_delay -clock CLK  -min 0.5  [get_ports {o_data[2]}]
set_output_delay -clock CLK  -min 0.5  [get_ports {o_data[1]}]
set_output_delay -clock CLK  -min 0.5  [get_ports {o_data[0]}]
set_drive 1  [get_ports clk]
set_drive 1  [get_ports rst_n]
set_drive 1  [get_ports i_valid]
set_drive 1  [get_ports o_ready]
set_drive 1  [get_ports {i_data[15]}]
set_drive 1  [get_ports {i_data[14]}]
set_drive 1  [get_ports {i_data[13]}]
set_drive 1  [get_ports {i_data[12]}]
set_drive 1  [get_ports {i_data[11]}]
set_drive 1  [get_ports {i_data[10]}]
set_drive 1  [get_ports {i_data[9]}]
set_drive 1  [get_ports {i_data[8]}]
set_drive 1  [get_ports {i_data[7]}]
set_drive 1  [get_ports {i_data[6]}]
set_drive 1  [get_ports {i_data[5]}]
set_drive 1  [get_ports {i_data[4]}]
set_drive 1  [get_ports {i_data[3]}]
set_drive 1  [get_ports {i_data[2]}]
set_drive 1  [get_ports {i_data[1]}]
set_drive 1  [get_ports {i_data[0]}]
