import os
import re

def generate_verilog_rom(input_txt_path, output_v_path, N=32):
    if not os.path.exists(input_txt_path): return
    with open(input_txt_path, 'r') as f:
        lines = f.readlines()
        
    with open(output_v_path, 'w') as f:
        f.write("`timescale 1ns/1ps\n\nmodule CSD_ROM_Table (\n")
        f.write("    input  wire [4:0] n_idx,  input  wire [4:0] k_idx,\n")
        f.write("    output reg  [1:0] sign1,  output reg  [3:0] shift1,\n") # [修改] 2-bit
        f.write("    output reg  [1:0] sign2,  output reg  [3:0] shift2\n);\n\n")
        f.write("    always @(*) begin\n")
        f.write("        sign1 = 2'b00; shift1 = 4'd0; sign2 = 2'b00; shift2 = 4'd0;\n\n")
        f.write("        case (k_idx)\n")

        for k in range(N):
            f.write(f"            5'd{k}: begin\n                case (n_idx)\n")
            for n in range(N):
                line_idx = n * N + k
                if line_idx < len(lines):
                    matches = re.findall(r'\((-?\d+),(\d+)\)', lines[line_idx].strip())
                    s1_bit = "2'b00"; p1_val = "4'd0"; s2_bit = "2'b00"; p2_val = "4'd0"
                    
                    if len(matches) >= 1:
                        s1, p1 = matches[0]
                        if s1 == "1": s1_bit = "2'b01"
                        elif s1 == "-1": s1_bit = "2'b10"
                        p1_val = f"4'd{p1}"
                        
                    if len(matches) >= 2:
                        s2, p2 = matches[1]
                        if s2 == "1": s2_bit = "2'b01"
                        elif s2 == "-1": s2_bit = "2'b10"
                        p2_val = f"4'd{p2}"

                    f.write(f"                    5'd{n:02d}: begin sign1 = {s1_bit}; shift1 = {p1_val:4}; sign2 = {s2_bit}; shift2 = {p2_val:4}; end\n")
            f.write("                endcase\n            end\n")
        f.write("        endcase\n    end\nendmodule\n")
        print("Successfully generate!")
        
if __name__ == "__main__":
    generate_verilog_rom("../../sim/V_ops.txt", "CSD_ROM_Table.v", N=32)