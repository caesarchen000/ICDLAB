import numpy as np

# ==========================================
# 硬體系統常數與 Bit-width 設定
# ==========================================
RANDOM_SEED = 67
AUTO_UNITY_GAIN = False

N = 32
V_BITS = 14       # 矩陣 V 的小數點位數 (Q14)
S1_SHIFT = 10     # Stage 1 算完後的右移量
OUTPUT_SHIFT = 5  # CORDIC Stage 算完後的右移量 (原 S2_SHIFT)
S3_SHIFT = 14     # Stage 3 算完後的最終右移量 (從 17 改為 14 以符合 gen_test)
V_SCALE = 1.103153 #np.sqrt(2/1.64676)

# Shift-and-Add 限制
MAX_TERMS = 3     # 硬體限制：每個常數最多由幾個 2 的次方相加減組成

# CORDIC 參數
STAGES = 11

# 取消 K_INV 的預先乘法補償，因為直接做向量旋轉
# 取而代之的是硬體會自帶一個固定的 Gain (CORDIC 旋轉增益 + Shift 所產生的等效縮放)
#HW_GAIN = 1.64676 * 2**(2*V_BITS - S1_SHIFT - S3_SHIFT - OUTPUT_SHIFT) * (V_SCALE**2) # 約 0.82338 (理論值需乘上此係數才能與硬體 Bit-True 對齊)
#HW_GAIN = 1
if AUTO_UNITY_GAIN:
    HW_GAIN = 1.0
else:
    HW_GAIN = (
        1.64676
        * 2**(2*V_BITS - S1_SHIFT - S3_SHIFT - OUTPUT_SHIFT)
        * (V_SCALE**2)
    )

print(f"HW_GAIN:{HW_GAIN}")

ATAN_TABLE_FULL = [8192, 4836, 2555, 1297, 651, 326, 163, 81, 41, 20, 10, 5]
ATAN_TABLE = ATAN_TABLE_FULL[:STAGES]

# Hardware bit design:
INPUT_PORT = 9   # 8-bit chip default; 9-bit sim for wider inter-pass storage
OUTPUT_PORT = 11

MAC_INPUT = 17
MAC_OUTPUT = 17
MAC_INTERMEDIATE = 27

CORDIC_INPUT = 17
CORDIC_INTERMEDIATE = 18
CORDIC_OUTPUT = 17