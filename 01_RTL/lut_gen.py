import numpy as np
import math
from datetime import datetime

# ==========================================
# 參數設定
# ==========================================
FILENAME = "LUT_chirp_v3.v"
AUTHOR = "Yu-Yan Zheng"
KEY_WIDTH_13 = 7
NUM_KEYS = 2**KEY_WIDTH_13
KEY_WIDTH_2 = 7
NUM_KEYS = 2**KEY_WIDTH_2
VALUE_WIDTH = 8
DATA_WIDTH = 2*VALUE_WIDTH
N = 32
MODULUS = 4294967297  # F_q = 2^32 + 1
PSI = 4               # Principal 32nd root of unity
SCALE_1 = 64           # for chirp13
SCALE_2 = 32           # for chirp2

# ==========================================
# 輔助函式
# ==========================================
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
        f.write(f"    output reg   [DATA_WIDTH-1:0] out\n")
        f.write(f");\n")
        f.write(f"    wire [REG_ADDRW+KEY_WIDTH-1:0] concat_sel = {{key, idx}};\n\n")
        f.write(f"    always @(*) begin\n")
        f.write(f"        case(concat_sel)\n")

        time = np.arange(1, N//2+1) # 1, 2 ..., 16
        
        
        # Traverse from k = 1 to 128 (Store Positive Key)
        for k in range(1, 129):
            a = k / 128.0
            if a % 1 == 0:
                a -= 1e-6 # since if k = 128, then tan(pi/2)->infty
            alpha = a * math.pi # alpha = angle
            
            c13_ideal = np.exp(-1j * math.pi * (time**2) * np.tan(alpha/2) )
            
            c13_r = np.round(c13_ideal.real * SCALE_1).astype(int)
            c13_i = np.round(c13_ideal.imag * SCALE_1).astype(int)
            
            c13_cr = [complex_represent(c13_r[i], c13_i[i]) for i in range(N//2)]

            if k == 128:
                print(alpha)
                print(c13_r)
                print(c13_i)
                print(c13_cr[0])

            for idx in range(N//2): # idx 0~15
                val = c13_cr[idx]
                addr = (k-1) * 16 + idx
                f.write(f"            {int(np.log2(N))-1+KEY_WIDTH_13}'d{addr:<5}: out = {DATA_WIDTH}'b{val:016b};\n")
                        
        # 兜底保護
        f.write(f"            default: out = {DATA_WIDTH}'d0;\n")
        f.write(f"        endcase\n")
        f.write(f"    end\n")
        f.write(f"endmodule\n")

        print(f">>> 已經生成module LUT_chirp13")
        
        f.write(f"\n")

        # A_alpha * exp(j * pi/N * t^2 * csc(alpha)) (Chirp II)
        f.write(f"module LUT_chirp2 #(\n")
        f.write(f"    parameter REG_ADDRW  = {int(np.log2(N))-1},\n")
        f.write(f"    parameter KEY_WIDTH  = {KEY_WIDTH_2},\n")
        f.write(f"    parameter DATA_WIDTH = {DATA_WIDTH}\n")
        f.write(f")(\n")
        f.write(f"    input         [REG_ADDRW-1:0] idx,\n")
        f.write(f"    input         [KEY_WIDTH-1:0] key,\n")
        f.write(f"    output reg   [DATA_WIDTH-1:0] out\n")
        f.write(f");\n")
        f.write(f"    wire [REG_ADDRW+KEY_WIDTH-1:0] concat_sel = {{key, idx}};\n\n")
        f.write(f"    always @(*) begin\n")
        f.write(f"        case(concat_sel)\n")

        t = np.arange(-16, 16)
        time = np.arange(1, N//2+1) # 1, 2 ..., 16
        
        # Traverse from k = 1 to 128 (Store Positive Key)
        for k in range(1, 129):
            
            a = k / 128.0 if k != 128 else 127/128
            alpha = a * math.pi # alpha = angle

            if np.abs(np.sin(alpha)) < 1e-10:
                alpha += 1e-5
            
            c2_ideal = np.exp( 1j * math.pi * (time**2) / np.sin(alpha) )
            A_alpha = np.sqrt((1 - 1j / np.tan(alpha)) / (2 * np.pi))
            #A_alpha = 1
            c2_ideal = c2_ideal*A_alpha
            c2_r = np.round(c2_ideal.real * SCALE_2).astype(int)
            c2_i = np.round(c2_ideal.imag * SCALE_2).astype(int)
            
            c2_cr = [complex_represent(c2_r[i], c2_i[i]) for i in range(N//2)]

            if k == 15:
                print(alpha)
                print(c2_r)
                print(c2_i)
                print(c2_cr[0])

            if k == 113:
                print(alpha)
                print(c2_r)
                print(c2_i)
                print(c2_cr[0])

            for idx in range(N//2): # idx 0~15
                val = c2_cr[idx]
                addr = (k-1) * 16 + idx
                f.write(f"            {int(np.log2(N))-1+KEY_WIDTH_2}'d{addr:<5}: out = {DATA_WIDTH}'b{val:016b};\n")
                        
        # 兜底保護
        f.write(f"            default: out = {DATA_WIDTH}'d0;\n")
        f.write(f"        endcase\n")
        f.write(f"    end\n")
        f.write(f"endmodule\n")
        
    print(f">>> 產生module LUT_chirp2完畢！已經生成完美的 {FILENAME}，可直接進行合成與驗證！")