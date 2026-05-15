import numpy as np
import struct
from new_hw_sim import theoretical_eigen_dfrft
from config import *

# --- 參數設定 (確保與 RTL 一致) ---
#N = 32
#V_BITS = 14
#S1_SHIFT = 10
#OUTPUT_SHIFT = 5  # CORDIC
#S3_SHIFT = 14     # Stage 3 截斷

def to_signed(val, bits):
    val = int(val) & ((1 << bits) - 1)
    if val >= (1 << (bits - 1)):
        val -= (1 << bits)
    return val

def hw_cordic_rotation(x_in, y_in, phase_in):
    ATAN_TABLE = [8192, 4836, 2555, 1297, 651, 326, 163, 81, 41, 20, 10]
    phase_in = to_signed(phase_in, 16)
    
    if phase_in > 16384 or phase_in < -16384:
        x, y = -x_in, -y_in
        z = to_signed(phase_in - 32768 if phase_in > 0 else phase_in + 32768, 16)
    else:
        x, y = x_in, y_in
        z = phase_in

    for i in range(11):
        sign = (z < 0)
        x_shift, y_shift = x >> i, y >> i
        if not sign:
            x_next, y_next, z_next = x - y_shift, y + x_shift, z - ATAN_TABLE[i]
        else:
            x_next, y_next, z_next = x + y_shift, y - x_shift, z + ATAN_TABLE[i]
        x, y, z = to_signed(x_next, 18), to_signed(y_next, 18), to_signed(z_next, 16)

    x_out = (x + (1 << (OUTPUT_SHIFT - 1))) >> OUTPUT_SHIFT
    y_out = (y + (1 << (OUTPUT_SHIFT - 1))) >> OUTPUT_SHIFT
    return x_out, y_out

def generate_all_keys_files():
    # 讀取 V_q.txt
    try:
        V_q = np.loadtxt("V_q.txt", dtype=np.int64)
    except FileNotFoundError:
        print("錯誤: 找不到 V_q.txt，請先用 hw_sim.py 生成。")
        return

    np.random.seed(67)
    # 控制振幅避免全範圍飽和影響真實 MSE 評估
    x_real = np.random.randint(-128, 127, size=N)
    x_imag = np.random.randint(-128, 127, size=N)

    # 1. 生成唯一的一組 input.txt (32 筆)
    with open("../pattern/input_all_keys.txt", "w") as f:
        for r, i in zip(x_real, x_imag):
            f.write(f"{(int(r) & 0xFF):02X} {(int(i) & 0xFF):02X}\n")

    print("已生成 input.txt (共 32 筆資料)")

    # 2. Stage 1 (與 Key 無關，只要算一次)
    y1_r_full, y1_i_full = np.zeros(N, dtype=np.int64), np.zeros(N, dtype=np.int64)
    for k in range(N):
        for n in range(N):
            y1_r_full[k] += V_q[n, k] * x_real[n]
            y1_i_full[k] += V_q[n, k] * x_imag[n]
            
    y1_r_q = (y1_r_full + (1 << (S1_SHIFT - 1))) >> S1_SHIFT
    y1_i_q = (y1_i_full + (1 << (S1_SHIFT - 1))) >> S1_SHIFT

    # DFrFT 的硬體系統真實增益
    # 3. 掃描所有 Key (-128 ~ 127) 並寫入 golden_all_keys.txt
    with open("../pattern/golden_all_keys.txt", "w") as f:
        print("開始生成 256 組 Key 的 Golden Patterns...")
        for test_key in range(-128, 128):
            
            # Stage 2: CORDIC
            y2_r = np.zeros(N, dtype=np.int64)
            y2_i = np.zeros(N, dtype=np.int64)
            for k in range(N):
                k_val = 32 if k == 31 else k
                phase_val = to_signed(-256 * k_val * test_key, 16)
                y2_r[k], y2_i[k] = hw_cordic_rotation(y1_r_q[k], y1_i_q[k], phase_val)

            # Stage 3: Matrix Mul
            y3_r = np.zeros(N, dtype=np.int64)
            y3_i = np.zeros(N, dtype=np.int64)
            for n in range(N):
                for k in range(N):
                    y3_r[n] += V_q[n, k] * y2_r[k]
                    y3_i[n] += V_q[n, k] * y2_i[k]
            
            out_r = (y3_r + (1 << (S3_SHIFT - 1))) >> S3_SHIFT
            out_i = (y3_i + (1 << (S3_SHIFT - 1))) >> S3_SHIFT

            # 理論值計算與縮放
            res_float = theoretical_eigen_dfrft(x_real, x_imag, test_key)
            res_float_scaled = res_float * HW_GAIN

            # 寫入 32 筆資料
            for i in range(N):
                hr_hex = (int(out_r[i]) & 0xFFFF)
                hi_hex = (int(out_i[i]) & 0xFFFF)
                tr_bits = struct.unpack('<Q', struct.pack('<d', float(res_float_scaled[i].real)))[0]
                ti_bits = struct.unpack('<Q', struct.pack('<d', float(res_float_scaled[i].imag)))[0]
                
                f.write(f"{hr_hex:04X} {hi_hex:04X} {tr_bits:016X} {ti_bits:016X}\n")

    print("成功產生 golden_all_keys.txt (共 8192 筆資料)！")

if __name__ == "__main__":
    generate_all_keys_files()