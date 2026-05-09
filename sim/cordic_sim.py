import numpy as np
import math
from plot_utility import *  # 確保同目錄下有 plot_utility.py

# ==========================================
# CORDIC 基本常數與工具
# ==========================================
STAGES = 11
OUTPUT_SHIFT = 5
ATAN_TABLE_FULL = [8192, 4836, 2555, 1297, 651, 326, 163, 81, 41, 20, 10, 5]

def get_k_inv(stages, frac_bits=14):
    K = 1.0
    for i in range(stages):
        K *= math.sqrt(1 + 2**(-2*i))
    return int(round((1 << frac_bits) / K))

def to_signed(val, bits):
    val = int(val) & ((1 << bits) - 1)
    if val >= (1 << (bits - 1)):
        val -= (1 << bits)
    return val

# ==========================================
# 硬體 Bit-True CORDIC 模型
# ==========================================
def hw_cordic(phase_in, stages, k_inv, atan_table, out_shift):
    """模擬 RTL CORDIC 旋轉運算"""
    phase_in = to_signed(phase_in, 16)
    
    # 象限映射 (Mapping to range -pi/2 ~ pi/2)
    if phase_in > 16384 or phase_in < -16384:
        x, y = -k_inv, 0
        z = to_signed(phase_in - 32768 if phase_in > 0 else phase_in + 32768, 16)
    else:
        x, y = k_inv, 0
        z = phase_in

    for i in range(stages):
        sign = (z < 0)
        x_shift, y_shift = x >> i, y >> i
        if not sign:
            x_next, y_next, z_next = x - y_shift, y + x_shift, z - atan_table[i]
        else:
            x_next, y_next, z_next = x + y_shift, y - x_shift, z + atan_table[i]
        x, y, z = to_signed(x_next, 16), to_signed(y_next, 16), to_signed(z_next, 16)

    # 輸出提取與四捨五入 (Rounding to integer)
    def extract_and_round(val):
        val_unsigned = val & 0xFFFF
        out_bits = 16 - out_shift
        main_mask = (1 << out_bits) - 1
        main = (val_unsigned >> out_shift) & main_mask
        round_bit = (val_unsigned >> (out_shift - 1)) & 1
        return to_signed((main + round_bit) & main_mask, out_bits)
    
    return extract_and_round(x), extract_and_round(y)

# ==========================================
# 主測試邏輯：計算 Lambda_alpha Match Rate
# ==========================================
def run_eigen_match_test(stages, out_shift):
    # 參數初始化
    k_inv = get_k_inv(stages)
    atan_table = ATAN_TABLE_FULL[:stages]
    
    # 模擬 DFrFT 的 k_orders (N=32)
    # 這裡直接用 0~31，或是你 DFrFT 裡算出來的固定序列均可
    N = 32
    k_orders = np.arange(N) 
    # 若要符合你 DFrFT 的特殊順序，可手動替換此處
    
    # 縮放係數：CORDIC 內部 1.0 = 2^14，輸出右移 out_shift
    scale = 2**(14 - out_shift)
    
    keys = np.arange(-128, 128) # 掃描所有 Key
    total_points = 0
    exact_matches = 0
    
    for key in keys:
        for k_idx in k_orders:
            # 1. 理論值計算
            angle_param = key * np.pi / 128
            phi = - k_idx * angle_param
            ideal_cos = np.cos(phi)
            ideal_sin = np.sin(phi)
            
            # 理論值量化為整數 (與 CORDIC 輸出對齊)
            ideal_q_cos = int(np.round(ideal_cos * scale))
            ideal_q_sin = int(np.round(ideal_sin * scale))
            
            # 2. 硬體 CORDIC 模擬
            # Phase 映射：pi 弧度對應 32768 LSBs，故 (key*pi/128) -> key * 256
            hw_phase = to_signed(-256 * k_idx * key, 16)
            hw_cos, hw_sin = hw_cordic(hw_phase, stages, k_inv, atan_table, out_shift)
            
            # 3. 比對
            if (hw_cos == ideal_q_cos) and (hw_sin == ideal_q_sin):
                exact_matches += 1
            total_points += 1
            
    return (exact_matches / total_points) * 100

# ==========================================
# Grid Search 與 Heatmap 繪製
# ==========================================
if __name__ == "__main__":
    results = []
    
    # 掃描範圍
    stages_range = [7, 8, 9, 10, 11, 12]
    shift_range = [5, 6, 7, 8, 9]
    
    print(">>> 正在進行 Eigenvalue 旋轉因子 (Lambda_alpha) Match Rate 掃描...")
    
    for stg in stages_range:
        for shf in shift_range:
            match_rate = run_eigen_match_test(stg, shf)
            
            # 為了相容你的 plot_heatmap，欄位名稱需保持一致
            results.append({
                "stages": stg,
                "shift": shf,
                "match_rate": match_rate
            })
            
            print(f"Stages: {stg:2d}, Shift: {shf:2d} | Match Rate: {match_rate:6.2f}%")

    # 繪圖
    # 使用你提供的 key_name "match_rate"
    plot_heatmap(results, "match_rate", filename="Heat_Eigen_Match.png")
    #plot_lines(results)
    
    print("\n分析完成。")