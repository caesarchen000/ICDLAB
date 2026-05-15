import numpy as np
import struct
from new_hw_sim import theoretical_eigen_dfrft

# --- 參數設定 (確保與 RTL 一致) ---
N = 32
V_BITS = 14
S1_SHIFT = 10
OUTPUT_SHIFT = 5  # CORDIC
S3_SHIFT = 14     # Stage 3 截斷
TEST_KEY = 64

def to_signed(val, bits):
    val = int(val) & ((1 << bits) - 1)
    if val >= (1 << (bits - 1)):
        val -= (1 << bits)
    return val

def realtobits(val):
    return struct.unpack('<Q', struct.pack('<d', float(val)))[0]

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

def generate_files():
    # 讀取你的 V_q.txt
    try:
        V_q = np.loadtxt("V_q.txt", dtype=np.int64)
    except FileNotFoundError:
        print("錯誤: 找不到 V_q.txt，請先用 hw_sim.py 生成。")
        return

    np.random.seed(42)
    x_real = np.random.randint(-128, 127, size=N)
    x_imag = np.random.randint(-128, 127, size=N)

    # 1. 生成 input.txt
    with open("../pattern/input.txt", "w") as f:
        for r, i in zip(x_real, x_imag):
            f.write(f"{(int(r) & 0xFF):02X} {(int(i) & 0xFF):02X}\n")

    # 2. 執行硬體管線模擬並記錄 Debug
    y1_r = np.zeros(N, dtype=np.int64)
    y1_i = np.zeros(N, dtype=np.int64)
    
    # Stage 1
    for k in range(N):
        for n in range(N):
            y1_r[k] += V_q[n, k] * x_real[n]
            y1_i[k] += V_q[n, k] * x_imag[n]
    y1_r = (y1_r + (1 << (S1_SHIFT - 1))) >> S1_SHIFT
    y1_i = (y1_i + (1 << (S1_SHIFT - 1))) >> S1_SHIFT

    # Stage 2
    y2_r = np.zeros(N, dtype=np.int64)
    y2_i = np.zeros(N, dtype=np.int64)
    for k in range(N):
        k_val = 32 if k == 31 else k
        phase_val = to_signed(-256 * k_val * TEST_KEY, 16)
        y2_r[k], y2_i[k] = hw_cordic_rotation(y1_r[k], y1_i[k], phase_val)

    # Stage 3
    y3_r = np.zeros(N, dtype=np.int64)
    y3_i = np.zeros(N, dtype=np.int64)
    for n in range(N):
        for k in range(N):
            y3_r[n] += V_q[n, k] * y2_r[k]
            y3_i[n] += V_q[n, k] * y2_i[k]
    
    out_r = (y3_r + (1 << (S3_SHIFT - 1))) >> S3_SHIFT
    out_i = (y3_i + (1 << (S3_SHIFT - 1))) >> S3_SHIFT

    # 3. 生成 debug.txt
    with open("../pattern/debug.txt", "w") as f:
        f.write("IDX | STAGE1_R STAGE1_I | STAGE2_R STAGE2_I | FINAL_R FINAL_I\n")
        f.write("-" * 65 + "\n")
        for k in range(N):
            f.write(f"{k:2d}  | {y1_r[k]:8d} {y1_i[k]:8d} | {y2_r[k]:8d} {y2_i[k]:8d} | {out_r[k]:8d} {out_i[k]:8d}\n")
    print("成功產生 debug.txt!可以對照 Verdi 裡面 RegFile 的數值了。")

    # 4. 生成 golden.txt (為配合你的 TB，假定理論值填 0，我們專注比對 Bit-true)
    res_float = theoretical_eigen_dfrft(x_real, x_imag, TEST_KEY)
    # DFrFT 的硬體系統真實增益
    HW_GAIN = 1.64676 / 2.0  # 約 0.82338
    # 將理論值乘上硬體增益，對齊基準線
    res_float_scaled = res_float * HW_GAIN

    with open("../pattern/golden.txt", "w") as f:
        for i in range(N):
            hr_hex = (int(out_r[i]) & 0xFFFF)
            hi_hex = (int(out_i[i]) & 0xFFFF)
            tr_bits = struct.unpack('<Q', struct.pack('<d', float(res_float_scaled[i].real)))[0]
            ti_bits = struct.unpack('<Q', struct.pack('<d', float(res_float_scaled[i].imag)))[0]
            
            f.write(f"{hr_hex:04X} {hi_hex:04X} {tr_bits:016X} {ti_bits:016X}\n")

    print("成功產生 golden.txt 與 input.txt!")

if __name__ == "__main__":
    generate_files()