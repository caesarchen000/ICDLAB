set_clock_latency 0.5  [get_clocks {CLK}]
set_clock_latency -source -early -min -rise  -0.290609 [get_ports {clk}] -clock CLK 
set_clock_latency -source -early -min -fall  -0.180195 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -min -rise  -0.290609 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -min -fall  -0.180195 [get_ports {clk}] -clock CLK 
