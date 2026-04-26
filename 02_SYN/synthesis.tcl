# 1. Read Design
set fp [open "../01_RTL/lut_rtl.f" r]
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

# 讀取檔案
read_file -format verilog $files

current_design Chirp_Generator
uniquify
link

# 2. Constraints (針對組合電路)
# 因為沒有 clock port，我們建立一個 Virtual Clock 來計算 Path Delay
# 假設你希望 Input -> Output 在 10ns 內完成
create_clock -name "vclk" -period 15

# 組合電路不需要 set_dont_touch_network 或 set_fix_hold (因為沒 Flip-Flops)
# 但需要設定 Input/Output Delay 來限制邏輯延遲
set_input_delay  1  -clock vclk [all_inputs]
set_output_delay 0.5  -clock vclk [all_outputs] 
# 上面這代表：Logic Delay + Output Delay (5) < Period (10)，即邏輯要在 5ns 內算完

# 環境設定
set_clock_uncertainty  0.1  [get_clocks vclk]
set_drive 1  [all_inputs]
set_load  10 [all_outputs]

set_fix_multiple_port_nets -all -buffer_constants

# 操作條件 (Operating Conditions)
set_operating_conditions -min_library fsa0m_a_generic_core_ff1p98vm40c -min BCCOM \
                         -max_library fsa0m_a_generic_core_ss1p62v125c -max WCCOM
set_wire_load_model -name G200K -library fsa0m_a_generic_core_tt1p8v25c

set_max_area 0
set_max_fanout 6 Chirp_Generator
set_boundary_optimization {"*"}

#source -echo -verbose ./your_design.sdc

############in sdc file
# Set the Optimization Constraints 
#create_clock -period 10 -name "clk_p_i" -waveform {0 5} "clk_p_i"
#set_dont_touch_network [get_ports clk_p_i]
#set_fix_hold [get_clocks clk_p_i]

# Define the design environment

#set_clock_uncertainty  0.1  [get_clocks clk_p_i]
#set_clock_latency      0.5  [get_clocks clk_p_i]
#set_input_delay -max 1 -clock clk_p_i [all_inputs]
#set_output_delay -min 0.5 -clock clk_p_i [all_outputs]
#set_drive 1  [all_inputs]
#set_load  10 [all_outputs]


#set_fix_multiple_port_nets -all -buffer_constants

#set_operating_conditions -min_library fsa0m_a_generic_core_ff1p98vm40c -min BCCOM -max_library fsa0m_a_generic_core_ss1p62v125c -max WCCOM
#set_wire_load_model -name G200K -library fsa0m_a_generic_core_tt1p8v25c

#set_max_area 0
#set_max_fanout 6 alu
#set_boundary_optimization {"*"}
#############in sdc file


check_design

# remove_attribute [find -hierarchy design {"*"}] dont_touch

# Map and Optimize the Design
compile -map_effort medium

# Analyze and debug the design
report_area > area_chirp.out
report_power > power_chirp.out
report_timing -path full -delay max > timing_chirp.out

#write -format db -hierarchy -output $active_design.db
write -format verilog -hierarchy -output Chirp_Generator_syn.v
write_sdf -version 2.1 -context verilog Chirp_Generator.sdf
write_sdc Chirp_Generator.sdc
