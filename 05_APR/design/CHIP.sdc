###################################################################

# Created by write_sdc on Sun May 10 00:28:35 2026

###################################################################
set sdc_version 1.8

# Innovus: set_units / set_max_area unsupported (CTE-25). MMMC owns corners;
# set_operating_conditions unsupported (TCLCMD-1014) — use mmmc.view delay corners.
# set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
# set_operating_conditions -max WCCOM -max_library                               \
# fsa0m_a_generic_core_ss1p62v125c\
#                          -min BCCOM -min_library                               \
# fsa0m_a_generic_core_ff1p98vm40c
# Wire-load lib must be one actually loaded by active MMMC views (typ TT not loaded for setup-only).
set_wire_load_model -name G200K -library fsa0m_a_generic_core_ss1p62v125c
# Very tight (e.g. 6) causes persistent max_fanout DRVs in APR before/incomplete CTS.
# Use a looser limit for implementation timing, or split synthesis vs APR SDC if you need 6 in DC.
set_max_fanout 32 [current_design]
# set_max_area 0
create_clock [get_ports clk]  -name CLK  -period 20  -waveform {0 10}
set_clock_latency 0.5  [get_clocks CLK]
set_clock_uncertainty 0.1  [get_clocks CLK]
# Innovus: no set_input_delay on clock root (TCLNL-330); latency above covers source.
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
