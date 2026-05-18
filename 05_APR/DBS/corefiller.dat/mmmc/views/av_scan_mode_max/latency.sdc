set_clock_latency 0.5  [get_clocks {CLK}]
set_clock_latency -source -early -max -rise  -1.09968 [get_ports {clk}] -clock CLK 
set_clock_latency -source -early -max -fall  -0.850787 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -rise  -1.09968 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -fall  -0.850787 [get_ports {clk}] -clock CLK 
