import numpy as np
import math
from datetime import datetime

# ==========================================
# 參數設定
# ==========================================
FILENAME = "LUT_chirp.v"
AUTHOR = "Yu-Yan Zheng"
KEY_WIDTH_13 = 7
NUM_KEYS = 2**KEY_WIDTH_13
KEY_WIDTH_2 = 8
NUM_KEYS = 2**KEY_WIDTH_2
VALUE_WIDTH = 8
DATA_WIDTH = 2*VALUE_WIDTH
N = 32
M = 2**32 + 1
J = 2**16
MODULUS = 4294967297  # F_q = 2^32 + 1
PSI = 4               # Principal 32nd root of unity
SCALE_1 = 64           # for chirp13
SCALE_2 = 32           # for chirp2

def mod_add(a, b): return (a + b) % M
def mod_sub(a, b): return (a - b) % M
def mod_mul(a, b): return (int(a) * int(b)) % M

# ==========================================
# 輔助函式
# ==========================================

def complex_to_scc(real, imag):
    r = real.astype(np.int64) % M
    i = imag.astype(np.int64) % M
    
    path1 = (r + (J * i) % M) % M
    path2 = (r - (J * i) % M) % M
    
    return path1, path2
    
def fnt_32(x, root=4):
    X = np.zeros(N, dtype=np.int64)
    for k in range(N):
        for n in range(N):
            wk = pow(int(root), k * n, M)
            X[k] = mod_add(X[k], mod_mul(x[n], wk))
    return X

def fnt(x_array, n_len, fq, psi):
    """ 1D Fermat Number Transform """
    X = [0] * n_len
    for k in range(n_len):
        sum_val = 0
        for n in range(n_len):
            val = (x_array[n] * pow(psi, n * k, fq)) % fq
            sum_val = (sum_val + val) % fq
        X[k] = sum_val
    return X

def complex_to_fq(re, im):
    """ 將複數 A + jB 映射到 GF(F_q) 中的單一整數 """
    fq = MODULUS
    re_mod = int(re) % fq
    im_mod = (int(im) * 65536) % fq
    val = (re_mod + im_mod) % fq
    return val

def complex_represent(re, im):
    """ 將複數 A + jB 包裝 """
    # 2's complement
    re_p = re if re >= 0 else (2**VALUE_WIDTH+re)
    im_p = im if im >= 0 else (2**VALUE_WIDTH+im)

    re_mod = int(re_p)
    im_mod = (int(im_p) * (2**VALUE_WIDTH))
    val = (re_mod + im_mod)
    return val

def fq_to_dim1(val):
    """ 轉換為 33-bit Diminished-1 格式 """
    if val == 0:
        return 2**32
    else:
        return val - 1

def get_invertible_val(val, fq):
    """ 確保數值在 F_q 中有模反元素 (與 F_q 互質) """
    # 因為 2^32+1 = 641 * 6700417 (非質數)
    # 若 gcd != 1 則代表不可逆，微調 + 1 避開死鎖
    while math.gcd(val, fq) != 1:
        val = (val + 1) % fq
    return val

def mod_inverse(val, fq):
    """ 計算精確的模反元素 (Modular Multiplicative Inverse) """
    # Python 3.8+ 支援 pow(val, -1, mod) 快速計算反元素
    return pow(val, -1, fq)

def bitrev5(x):
    """ 5-bit Bit-Reversal for N=32 """
    return int('{:05b}'.format(x)[::-1], 2)

# ==========================================
# 主程式：生成包含加解密的完整 LUT_chirp.v
# ==========================================
if __name__ == "__main__":
    print(f">>> 開始生成 {FILENAME} ... (包含全部 {NUM_KEYS})")
    header = f"""/********************************************************************
* Filename: {FILENAME}
* Authors:
*     {AUTHOR}
* Description:
*     LUT for Chirp Signals (without F_q mapping, Diminished-1)
* Note:
*     key: 7-bit unsigned integer (1 ~ 128). Order a = key / 64, assume angle 0 isn't considered
*     out: 16-bit
*     (Complex mapped via: Real + Imag * 2^16 mod 2^32+1)
*     exp(-j * pi/N * t^2 * tan(alpha/2)) (Chirp I & III)
*     exp(j * pi/N * t^2 * csc(alpha)) (Chirp II)
* Review History:
*     {datetime.now().strftime("%Y.%m.%d")}    {AUTHOR}
*********************************************************************/\n
"""
    with open(FILENAME, "w") as f:
        # --- 寫入 Verilog Module 標頭 ---
        f.write(header)
        # exp(-j * pi/N * t^2 * tan(alpha/2)) (Chirp I & III)
        f.write(f"module LUT_chirp13 #(\n")
        f.write(f"    parameter REG_ADDRW  = {int(np.log2(N))-1},\n")
        f.write(f"    parameter KEY_WIDTH  = {KEY_WIDTH_13},\n")
        f.write(f"    parameter DATA_WIDTH = {DATA_WIDTH}\n")
        f.write(f")(\n")
        f.write(f"    input         [REG_ADDRW-1:0] idx,\n")
        f.write(f"    input         [KEY_WIDTH-1:0] key,\n")
        f.write(f"    output reg   [2*DATA_WIDTH-1:0] out\n")
        f.write(f");\n")
        f.write(f"    wire [REG_ADDRW+KEY_WIDTH-1:0] concat_sel = {{key, idx}};\n\n")
        f.write(f"    always @(*) begin\n")
        f.write(f"        case(concat_sel)\n")

        t = np.arange(-N//2, N//2)
        time = np.arange(1, N//2+1) # 1, 2 ..., 16
        
        # Traverse from k = 1 to 128 (Store Positive Key)
        for k in range(1, 129):
            a = k / 128.0
            if a % 1 == 0:
                a -= 1e-6 # since if k = 128, then tan(pi/2)->infty
            alpha = a * math.pi # alpha = angle
            
            c13_ideal = np.exp(-1j * math.pi * (t**2) * np.tan(alpha/2) )
            
            c13_r = np.round(c13_ideal.real * SCALE_1).astype(int)
            c13_i = np.round(c13_ideal.imag * SCALE_1).astype(int)
            
            c13_cr = [complex_represent(c13_r[i], c13_i[i]) for i in range(N)]

            # if k == 128:
            #     print(alpha)
            #     print(c13_r)
            #     print(c13_i)
            #     print(c13_cr[0])

            for idx in range(N//2): # idx 0~15
                val0 = c13_cr[2*idx]
                val1 = c13_cr[2*idx+1]
                addr = (k-1) * 16 + idx
                f.write(f"            {int(np.log2(N))-1+KEY_WIDTH_13}'d{addr:<5}: out = {2*DATA_WIDTH}'b{val1:016b}{val0:016b};\n")
                        
        # 兜底保護
        f.write(f"            default: out = {2*DATA_WIDTH}'d0;\n")
        f.write(f"        endcase\n")
        f.write(f"    end\n")
        f.write(f"endmodule\n")

        print(f">>> 已經生成module LUT_chirp13")
        
        f.write(f"\n")

        # ==========================================
        # LUT_chirp2_pos (正角度：包含 0 ~ 127)
        # ==========================================
        f.write(f"module LUT_chirp2_pos #(\n")
        f.write(f"    parameter REG_ADDRW  = {int(np.log2(N))-1},\n")
        f.write(f"    parameter KEY_WIDTH  = {KEY_WIDTH_2},\n")
        f.write(f"    parameter DATA_WIDTH = 33\n")
        f.write(f")(\n")
        f.write(f"    input         [REG_ADDRW-1:0] idx,\n")
        f.write(f"    input         [KEY_WIDTH-1:0] key,\n")
        f.write(f"    output reg   [2*DATA_WIDTH-1:0] out\n")
        f.write(f");\n")
        f.write(f"    wire [REG_ADDRW+KEY_WIDTH-1:0] concat_sel = {{key, idx}};\n\n")
        f.write(f"    always @(*) begin\n")
        f.write(f"        case(concat_sel)\n")

        t = np.arange(-16, 16)
        
        # 只跑 0 到 127
        for k in range(0, 128):
            a = k / 128.0
            alpha = a * math.pi
            if np.abs(np.sin(alpha)) < 1e-10: alpha += 1e-10
            
            c2_ideal = np.exp( 1j * math.pi * (t**2) / np.sin(alpha) )
            A_alpha = np.sqrt((1 - 1j / np.tan(alpha)) / (2 * np.pi))
            c2_ideal = c2_ideal * A_alpha
            c2_r = np.round(c2_ideal.real * SCALE_2).astype(int)
            c2_i = np.round(c2_ideal.imag * SCALE_2).astype(int)
            
            c2_r[16] = SCALE_2
            c2_i[16] = 0
            
            c2_p1, _ = complex_to_scc(c2_r, c2_i)
            C2_p1 = fnt_32(c2_p1)
            mapped_key = k & 0xFF
            
            for idx in range(N//2): 
                br_idx_0, br_idx_1 = bitrev5(2 * idx), bitrev5(2 * idx + 1)
                val0 = C2_p1[br_idx_0] - 1 if C2_p1[br_idx_0] > 0 else 2**32
                val1 = C2_p1[br_idx_1] - 1 if C2_p1[br_idx_1] > 0 else 2**32
                addr = mapped_key * 16 + idx
                f.write(f"            12'd{addr:<5}: out = 66'b{val1:033b}{val0:033b};\n")
                        
        f.write(f"            default: out = {2*33}'d0;\n")
        f.write(f"        endcase\n")
        f.write(f"    end\n")
        f.write(f"endmodule\n\n")

        # ==========================================
        # LUT_chirp2_neg (負角度：包含 -128 ~ -1)
        # ==========================================
        f.write(f"module LUT_chirp2_neg #(\n")
        f.write(f"    parameter REG_ADDRW  = {int(np.log2(N))-1},\n")
        f.write(f"    parameter KEY_WIDTH  = {KEY_WIDTH_2},\n")
        f.write(f"    parameter DATA_WIDTH = 33\n")
        f.write(f")(\n")
        f.write(f"    input         [REG_ADDRW-1:0] idx,\n")
        f.write(f"    input         [KEY_WIDTH-1:0] key,\n")
        f.write(f"    output reg   [2*DATA_WIDTH-1:0] out\n")
        f.write(f");\n")
        f.write(f"    wire [REG_ADDRW+KEY_WIDTH-1:0] concat_sel = {{key, idx}};\n\n")
        # ...
        f.write(f"    always @(*) begin\n")
        f.write(f"        case(concat_sel)\n")

        # 只跑 -128 到 -1
        for k in range(-128, 0):
            a = k / 128.0
            alpha = a * math.pi
            if np.abs(np.sin(alpha)) < 1e-10: alpha += 1e-10
            
            c2_ideal = np.exp( 1j * math.pi * (t**2) / np.sin(alpha) )
            A_alpha = np.sqrt((1 - 1j / np.tan(alpha)) / (2 * np.pi))
            c2_ideal = c2_ideal * A_alpha
            c2_r = np.round(c2_ideal.real * SCALE_2).astype(int)
            c2_i = np.round(c2_ideal.imag * SCALE_2).astype(int)
            
            c2_r[16] = SCALE_2
            c2_i[16] = 0
            
            c2_p1, _ = complex_to_scc(c2_r, c2_i)
            C2_p1 = fnt_32(c2_p1)
            mapped_key = k & 0xFF
            
            for idx in range(N//2): 
                br_idx_0, br_idx_1 = bitrev5(2 * idx), bitrev5(2 * idx + 1)
                val0 = C2_p1[br_idx_0] - 1 if C2_p1[br_idx_0] > 0 else 2**32
                val1 = C2_p1[br_idx_1] - 1 if C2_p1[br_idx_1] > 0 else 2**32
                addr = mapped_key * 16 + idx
                f.write(f"            12'd{addr:<5}: out = 66'b{val1:033b}{val0:033b};\n")
                        
        f.write(f"            default: out = {2*33}'d0;\n")
        f.write(f"        endcase\n")
        f.write(f"    end\n")
        f.write(f"endmodule\n")

    print(f">>> 產生module LUT_chirp2完畢！已經生成完美的 {FILENAME}，可直接進行合成與驗證！")

    '''
        # A_alpha * exp(j * pi/N * t^2 * csc(alpha)) (Chirp II)
        f.write(f"module LUT_chirp2 #(\n")
        f.write(f"    parameter REG_ADDRW  = {int(np.log2(N))-1},\n")
        f.write(f"    parameter KEY_WIDTH  = {KEY_WIDTH_2},\n")
        f.write(f"    parameter DATA_WIDTH = 33\n")
        f.write(f")(\n")
        f.write(f"    input         [REG_ADDRW-1:0] idx,\n")
        f.write(f"    input         [KEY_WIDTH-1:0] key,\n")
        f.write(f"    output reg   [2*DATA_WIDTH-1:0] out\n")
        f.write(f");\n")
        f.write(f"    wire [REG_ADDRW+KEY_WIDTH-1:0] concat_sel = {{key, idx}};\n\n")
        f.write(f"    always @(*) begin\n")
        f.write(f"        case(concat_sel)\n")

        # t = np.arange(-N//2, N//2)
        t = np.arange(-16, 16)
        time = np.arange(1, N//2+1) # 1, 2 ..., 16
        
        # Traverse from k = -128 to 127
        for k in range(-128, 128):
            a = k / 128.0
            alpha = a * math.pi # alpha = angle

            if np.abs(np.sin(alpha)) < 1e-10:
                alpha += 1e-10
            
            c2_ideal = np.exp( 1j * math.pi * (t**2) / np.sin(alpha) )
            A_alpha = np.sqrt((1 - 1j / np.tan(alpha)) / (2 * np.pi))
            #A_alpha = 1
            c2_ideal = c2_ideal*A_alpha
            c2_r = np.round(c2_ideal.real * SCALE_2).astype(int)
            c2_i = np.round(c2_ideal.imag * SCALE_2).astype(int)

            # 🌟 補上你在 sim.py 裡的 t=0 寫死 Bug！
            c2_r[16] = SCALE_2
            c2_i[16] = 0
            
            c2_p1, c2_p2 = complex_to_scc(c2_r, c2_i)
            C2_p1 = fnt_32(c2_p1)

            # if k == 15 or k == -15:
            #     print(f"k={k}: {C2_p1}")

            mapped_key = k & 0xFF
            for idx in range(N//2): # idx 0~15
                # 1. 取得硬體在這個 Cycle 會同時要求的兩個「線性位址」(偶數與奇數)
                idx_0 = 2 * idx
                idx_1 = 2 * idx + 1
                
                # 2. 套用 5-bit 反轉，找出這些資料在 FNT 打亂後的實際位置
                br_idx_0 = bitrev5(idx_0)
                br_idx_1 = bitrev5(idx_1)
                
                # 3. 抓取這兩個位置的 Path 1 資料 (Path 2 就放心交給硬體的 -key 去處理)
                val0 = C2_p1[br_idx_0] - 1 if C2_p1[br_idx_0] > 0 else 2**32
                val1 = C2_p1[br_idx_1] - 1 if C2_p1[br_idx_1] > 0 else 2**32
                
                addr = mapped_key * 16 + idx
                f.write(f"            12'd{addr:<5}: out = 66'b{val1:033b}{val0:033b};\n")
                        
        # 兜底保護
        f.write(f"            default: out = {2*33}'d0;\n")
        f.write(f"        endcase\n")
        f.write(f"    end\n")
        f.write(f"endmodule\n")
    '''