import numpy as np
import math
from datetime import datetime

# ==========================================
# 參數設定
# ==========================================
FILENAME = "LUT_chirp.v"
AUTHOR = "Guan-Yi Tsen"
KEY_WIDTH = 8
NUM_KEYS = 2**KEY_WIDTH
N = 32
MODULUS = 4294967297  # F_q = 2^32 + 1
PSI = 4               # Principal 32nd root of unity
SCALE = 127           # 8-bit 量化放大倍率 (密碼學中 SCALE 開多大都無損)

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
    print(f">>> 開始生成 {FILENAME} ... (包含全部 {NUM_KEYS} 把 Key 與模反元素)")
    header = f"""/********************************************************************
* Filename: {FILENAME}
* Authors:
*     {AUTHOR}
* Description:
*     LUT for Chirp Signals (33-bit F_q mapping, Diminished-1)
* Note:
*     key: 8-bit signed integer (-128 ~ 127). Order a = key / 64.
*     (Negative keys will fetch modular multiplicative inverses)
*     out: 33-bit Diminished-1 encoded integer.
*     (Complex mapped via: Real + Imag * 2^16 mod 2^32+1)
*     sel = 0: exp(-j * pi/N * t^2 * tan(alpha/2)) (Chirp I & III)
*     sel = 1: FNT{{ exp(j * pi/N * t^2 * csc(alpha)) }} (Chirp II FNT)
* Review History:
*     {datetime.now().strftime("%Y.%m.%d")}    {AUTHOR}
*********************************************************************/\n
"""
    with open(FILENAME, "w") as f:
        # --- 寫入 Verilog Module 標頭 ---
        f.write(header)
        f.write(f"module LUT_chirp #(\n")
        f.write(f"    parameter REG_ADDRW  = {int(np.log2(N))},\n")
        f.write(f"    parameter KEY_WIDTH  = {KEY_WIDTH},\n")
        f.write(f"    parameter DATA_WIDTH = 33\n")
        f.write(f")(\n")
        f.write(f"    input                         sel,\n")
        f.write(f"    input         [REG_ADDRW-1:0] idx,\n")
        f.write(f"    input  signed [KEY_WIDTH-1:0] key,\n")
        f.write(f"    output reg   [DATA_WIDTH-1:0] out\n")
        f.write(f");\n")
        f.write(f"    wire [13:0] concat_sel = {{sel, key, idx}};\n\n")
        f.write(f"    always @(*) begin\n")
        f.write(f"        case(concat_sel)\n")

        time = np.arange(-N//2, N//2)
        
        # --- 開始計算所有 Key 與其反元素 ---
        for sel in [0, 1]:
            # 遍歷 k = 0 到 128 (正向 Key)
            for k in range(129):
                a = k / 64.0
                if a % 1 == 0:
                    a += 1e-6
                
                alpha = a * (math.pi / 2)
                
                c13_ideal = np.exp(-1j * math.pi * (time**2) * np.tan(alpha/2) / N)
                c2_ideal  = np.exp( 1j * math.pi * (time**2) / np.sin(alpha) / N)
                
                c13_r = np.round(c13_ideal.real * SCALE).astype(int)
                c13_i = np.round(c13_ideal.imag * SCALE).astype(int)
                c2_r  = np.round(c2_ideal.real * SCALE).astype(int)
                c2_i  = np.round(c2_ideal.imag * SCALE).astype(int)
                
                c13_fq = [complex_to_fq(c13_r[i], c13_i[i]) for i in range(N)]
                c2_fq  = [complex_to_fq(c2_r[i], c2_i[i]) for i in range(N)]
                
                # 計算 Chirp II 的 FNT 頻譜
                c2_fnt = fnt(c2_fq, N, MODULUS, PSI)
                
                for idx in range(N):
                    # 選擇 Chirp (sel=0: Chirp I/III, sel=1: Chirp II FNT)
                    val = c13_fq[idx] if sel == 0 else c2_fnt[idx]
                    
                    # 保證可逆性，並取得完美的解密反元素！
                    val = get_invertible_val(val, MODULUS)
                    inv_val = mod_inverse(val, MODULUS)
                    
                    # 1. 寫入正向 (加密) Key = k
                    concat_fwd = sel * 8192 + k * 32 + idx
                    f.write(f"            14'd{concat_fwd:<5}: out = 33'h{fq_to_dim1(val):09X};\n")
                    
                    # 2. 寫入負向 (解密) Key = -k (在 8-bit 二補數中對應 256 - k)
                    if k != 0 and k != 128:
                        neg_k = 256 - k
                        concat_inv = sel * 8192 + neg_k * 32 + idx
                        f.write(f"            14'd{concat_inv:<5}: out = 33'h{fq_to_dim1(inv_val):09X};\n")
                        
        # 兜底保護
        f.write(f"            default: out = 33'h100000000;\n")
        f.write(f"        endcase\n")
        f.write(f"    end\n")
        f.write(f"endmodule\n")
        
    print(f">>> 產生完畢！已經生成完美的 {FILENAME}，可直接進行合成與驗證！")