import os
import re

def generate_rom_module(f, module_name, lines, N, is_even):
    f.write(f"module {module_name} (\n")
    f.write("    input  wire [4:0] n_idx,  input  wire [4:0] k_idx,\n")
    f.write("    output reg  [1:0] sign1,  output reg  [3:0] shift1,\n")
    f.write("    output reg  [1:0] sign2,  output reg  [3:0] shift2,\n")
    # [新增] 第三個 term 的輸出腳位
    f.write("    output reg  [1:0] sign3,  output reg  [3:0] shift3\n);\n\n")
    
    f.write("    always @(*) begin\n")
    # [修正] 對齊 PE.v 邏輯：2'b10 代表 0 (略過), 2'b00 代表加, 2'b01 代表減
    # [新增] 預設加上 sign3 和 shift3
    f.write("        sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0;\n\n")
    f.write("        case (k_idx)\n")

    for k in range(N):
        # [核心優化] 預先過濾掉絕對用不到的 n
        valid_n = []
        for n in range( (N // 2) + 1):
            # Even ROM (PE0/2) 不會遇到 (k奇數 AND n奇數)
            if is_even and (k % 2 == 1 and n % 2 == 1): continue
            # Odd ROM (PE1/3) 不會遇到 (k偶數 AND n偶數)
            if not is_even and (k % 2 == 0 and n % 2 == 0): continue
            valid_n.append(n)
        
        # 如果這個 k 裡面沒有任何有效的 n，連 case 都不用開了
        if not valid_n: continue

        f.write(f"            5'd{k}: begin\n                case (n_idx)\n")
        for n in valid_n:
            line_idx = n * N + k
            if line_idx < len(lines):
                matches = re.findall(r'\((-?\d+),(\d+)\)', lines[line_idx].strip())
                s1_bit = "2'b10"; p1_val = "4'd0"
                s2_bit = "2'b10"; p2_val = "4'd0"
                s3_bit = "2'b10"; p3_val = "4'd0"  # [新增] 初始化第三個 term
                
                if len(matches) >= 1:
                    s1, p1 = matches[0]
                    if s1 == "1": s1_bit = "2'b00"
                    elif s1 == "-1": s1_bit = "2'b01"
                    p1_val = f"4'd{p1}"
                    
                if len(matches) >= 2:
                    s2, p2 = matches[1]
                    if s2 == "1": s2_bit = "2'b00"
                    elif s2 == "-1": s2_bit = "2'b01"
                    p2_val = f"4'd{p2}"

                # [新增] 擷取第三個 term
                if len(matches) >= 3:
                    s3, p3 = matches[2]
                    if s3 == "1": s3_bit = "2'b00"
                    elif s3 == "-1": s3_bit = "2'b01"
                    p3_val = f"4'd{p3}"

                # [進階瘦身] 如果這個點矩陣是全 0 (三個 sign 都是 10)，直接略過讓 default 處理
                if s1_bit != "2'b10" or s2_bit != "2'b10" or s3_bit != "2'b10":
                    f.write(f"                    5'd{n:02d}: begin sign1 = {s1_bit}; shift1 = {p1_val:4}; sign2 = {s2_bit}; shift2 = {p2_val:4}; sign3 = {s3_bit}; shift3 = {p3_val:4}; end\n")
        f.write(f"                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end\n")
        f.write("                endcase\n            end\n")
    f.write("        endcase\n    end\nendmodule\n\n")

def generate_verilog_rom(input_txt_path, output_v_path, N=32):
    if not os.path.exists(input_txt_path): return
    with open(input_txt_path, 'r') as f:
        lines = f.readlines()
        
    with open(output_v_path, 'w') as f:
        f.write("`timescale 1ns/1ps\n\n")
        # 同時產生奇、偶兩個優化過後的 ROM
        generate_rom_module(f, "CSD_ROM_Table_even", lines, N, is_even=True)
        generate_rom_module(f, "CSD_ROM_Table_odd", lines, N, is_even=False)
        
    print("Successfully generated CSD_ROM_Table_even and CSD_ROM_Table_odd with 3-Terms!")

if __name__ == "__main__":
    generate_verilog_rom("../00_TESTBED/gen/V_ops.txt", "CSD_ROM_Table.v", N=32)