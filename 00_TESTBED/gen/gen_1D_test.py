import numpy as np
import struct
from hw_sim_0610 import theoretical_eigen_dfrft, hw_cordic_rotation

from config import *

# --- 參數設定 (確保與 RTL / hw_sim_0610.py 一致) ---
TEST_KEY = 64


def to_signed(val, bits):
    """
    Match hw_sim_0610.py's signed wrapping behavior.
    Works for both scalars and numpy arrays.
    """
    mask = (1 << bits) - 1
    val_arr = np.asarray(val, dtype=np.int64) & mask
    signed = np.where(val_arr >= (1 << (bits - 1)), val_arr - (1 << bits), val_arr)
    if signed.ndim == 0:
        return int(signed)
    return signed


def realtobits(val):
    return struct.unpack('<Q', struct.pack('<d', float(val)))[0]


def _hw_cordic_rotation(x_in, y_in, phase_in):
    """
    Same bit-width flow as hw_sim_0610.py:
      input        : CORDIC_INPUT
      iteration    : CORDIC_INTERMEDIATE
      phase        : 16-bit signed
      output shift : OUTPUT_SHIFT
      output       : CORDIC_OUTPUT
    """
    x_in = to_signed(x_in, CORDIC_INPUT)
    y_in = to_signed(y_in, CORDIC_INPUT)
    phase_in = to_signed(phase_in, 16)

    if phase_in > 16384 or phase_in < -16384:
        x, y = -x_in, -y_in
        z = to_signed(phase_in - 32768 if phase_in > 0 else phase_in + 32768, 16)
    else:
        x, y = x_in, y_in
        z = phase_in

    for i in range(STAGES):
        sign = (z < 0)
        x_shift, y_shift = x >> i, y >> i
        if not sign:
            x_next, y_next, z_next = x - y_shift, y + x_shift, z - ATAN_TABLE[i]
        else:
            x_next, y_next, z_next = x + y_shift, y - x_shift, z + ATAN_TABLE[i]

        x = to_signed(x_next, CORDIC_INTERMEDIATE)
        y = to_signed(y_next, CORDIC_INTERMEDIATE)
        z = to_signed(z_next, 16)

    x_out = (x + (1 << (OUTPUT_SHIFT - 1))) >> OUTPUT_SHIFT
    y_out = (y + (1 << (OUTPUT_SHIFT - 1))) >> OUTPUT_SHIFT

    x_out = to_signed(x_out, CORDIC_OUTPUT)
    y_out = to_signed(y_out, CORDIC_OUTPUT)
    return x_out, y_out

def hw_dfrft_pipeline(x_real, x_imag, key, V_q):
    # input storage
    x_real = to_signed(x_real, INPUT_PORT)
    x_imag = to_signed(x_imag, INPUT_PORT)

    # [Stage 1: V^T * x]
    x_real = to_signed(x_real, MAC_INPUT)
    x_imag = to_signed(x_imag, MAC_INPUT)
    y1_r_full, y1_i_full = np.zeros(N, dtype=np.int64), np.zeros(N, dtype=np.int64)
    for k in range(N):
        for n in range(N):
            y1_r_full[k] += to_signed(V_q[n, k] * x_real[n], MAC_INTERMEDIATE)
            y1_i_full[k] += to_signed(V_q[n, k] * x_imag[n], MAC_INTERMEDIATE)
            
    y1_r_q = to_signed((y1_r_full + (1 << (S1_SHIFT - 1))) >> S1_SHIFT, MAC_OUTPUT)
    y1_i_q = to_signed((y1_i_full + (1 << (S1_SHIFT - 1))) >> S1_SHIFT, MAC_OUTPUT)

    # [Stage 2: CORDIC Rotation] 👉 結合 gen_test 邏輯，直接做旋轉
    y2_r_q = np.zeros(N, dtype=np.int64)
    y2_i_q = np.zeros(N, dtype=np.int64)
    for k in range(N):
        k_val = N if (N % 2 == 0 and k == N - 1) else k
        phase_val = to_signed(-256 * k_val * key, 16)
        y2_r_q[k], y2_i_q[k] = hw_cordic_rotation(y1_r_q[k], y1_i_q[k], phase_val)

    # [Stage 3: V * y2]
    y2_r_q = to_signed(y2_r_q, MAC_INPUT)
    y2_i_q = to_signed(y2_i_q, MAC_INPUT)
    y3_r_full, y3_i_full = np.zeros(N, dtype=np.int64), np.zeros(N, dtype=np.int64)
    for n in range(N):
        for k in range(N):
            y3_r_full[n] += to_signed(V_q[n, k] * y2_r_q[k], MAC_INTERMEDIATE)
            y3_i_full[n] += to_signed(V_q[n, k] * y2_i_q[k], MAC_INTERMEDIATE)

    out_r = to_signed((y3_r_full + (1 << (S3_SHIFT - 1))) >> S3_SHIFT, MAC_OUTPUT)
    out_i = to_signed((y3_i_full + (1 << (S3_SHIFT - 1))) >> S3_SHIFT, MAC_OUTPUT)

    # output storage
    out_r = to_signed(out_r, OUTPUT_PORT)
    out_i = to_signed(out_i, OUTPUT_PORT)
    return out_r, out_i

def hw_dfrft_pipeline_bittrue(x_real, x_imag, key, V_q):
    """
    Bit-true flow copied from hw_sim_0610.py's hw_dfrft_pipeline(),
    but returns debug stage values for pattern/debug.txt generation.
    """
    # input storage: INPUT_PORT signed
    x_real = to_signed(x_real, INPUT_PORT)
    x_imag = to_signed(x_imag, INPUT_PORT)

    # Stage 1: V^T * x
    x_real_mac = to_signed(x_real, MAC_INPUT)
    x_imag_mac = to_signed(x_imag, MAC_INPUT)
    y1_r_full = np.zeros(N, dtype=np.int64)
    y1_i_full = np.zeros(N, dtype=np.int64)

    for k in range(N):
        for n in range(N):
            y1_r_full[k] += to_signed(V_q[n, k] * x_real_mac[n], MAC_INTERMEDIATE)
            y1_i_full[k] += to_signed(V_q[n, k] * x_imag_mac[n], MAC_INTERMEDIATE)

    y1_r = to_signed((y1_r_full + (1 << (S1_SHIFT - 1))) >> S1_SHIFT, MAC_OUTPUT)
    y1_i = to_signed((y1_i_full + (1 << (S1_SHIFT - 1))) >> S1_SHIFT, MAC_OUTPUT)

    # Stage 2: CORDIC rotation
    y2_r = np.zeros(N, dtype=np.int64)
    y2_i = np.zeros(N, dtype=np.int64)
    for k in range(N):
        # Same k_orders behavior as hw_sim_0610.py for N=32:
        # k_orders = [0, 1, ..., 30, 32]
        k_val = N if (N % 2 == 0 and k == N - 1) else k
        phase_val = to_signed(-256 * k_val * key, 16)
        y2_r[k], y2_i[k] = hw_cordic_rotation(y1_r[k], y1_i[k], phase_val)

    # Stage 3: V * y2
    y2_r_mac = to_signed(y2_r, MAC_INPUT)
    y2_i_mac = to_signed(y2_i, MAC_INPUT)
    y3_r_full = np.zeros(N, dtype=np.int64)
    y3_i_full = np.zeros(N, dtype=np.int64)

    for n in range(N):
        for k in range(N):
            y3_r_full[n] += to_signed(V_q[n, k] * y2_r_mac[k], MAC_INTERMEDIATE)
            y3_i_full[n] += to_signed(V_q[n, k] * y2_i_mac[k], MAC_INTERMEDIATE)

    out_r = to_signed((y3_r_full + (1 << (S3_SHIFT - 1))) >> S3_SHIFT, MAC_OUTPUT)
    out_i = to_signed((y3_i_full + (1 << (S3_SHIFT - 1))) >> S3_SHIFT, MAC_OUTPUT)

    # output storage: OUTPUT_PORT signed
    out_r = to_signed(out_r, OUTPUT_PORT)
    out_i = to_signed(out_i, OUTPUT_PORT)
    return y1_r, y1_i, y2_r, y2_i, out_r, out_i


def generate_files():
    # 讀取 hw_sim_0610.py 產生的 V_q.txt
    try:
        V_q = np.loadtxt("V_q.txt", dtype=np.int64)
    except FileNotFoundError:
        print("錯誤: 找不到 V_q.txt，請先執行 hw_sim_0610.py 生成。")
        return

    np.random.seed(RANDOM_SEED)

    # 與 hw_sim_0610.py single case 一致的 input
    t_n = np.arange(N)
    x_test_float = 100 * np.exp(-(t_n - N / 3) ** 2 / (N / 8)) + 1j * 50 * np.sin(
        4 * np.pi * t_n / N
    )
    x_real = np.clip(np.round(x_test_float.real), -128, 127).astype(np.int64)
    x_imag = np.clip(np.round(x_test_float.imag), -128, 127).astype(np.int64)

    # 1. 生成 input.txt
    with open("../pattern/input.txt", "w") as f:
        for r, i in zip(x_real, x_imag):
            f.write(f"{(int(r) & 0xFF):02X} {(int(i) & 0xFF):02X}\n")

    # 2. 執行 bit-true 硬體管線模擬並記錄 debug
    y1_r, y1_i, y2_r, y2_i, out_r, out_i = hw_dfrft_pipeline_bittrue(
        x_real, x_imag, TEST_KEY, V_q
    )

    print(f"out_r:{out_r}")
    print(f"out_i:{out_i}")

    hw_out_r, hw_out_i = hw_dfrft_pipeline(x_real, x_imag, TEST_KEY, V_q)
    print(f"hw_out_r:{hw_out_r}")
    print(f"hw_out_i:{hw_out_i}")

    # 3. 生成 debug.txt
    with open("../pattern/debug.txt", "w") as f:
        f.write("IDX | STAGE1_R STAGE1_I | STAGE2_R STAGE2_I | FINAL_R FINAL_I\n")
        f.write("-" * 65 + "\n")
        for k in range(N):
            f.write(
                f"{k:2d}  | {int(y1_r[k]):8d} {int(y1_i[k]):8d} | "
                f"{int(y2_r[k]):8d} {int(y2_i[k]):8d} | "
                f"{int(out_r[k]):8d} {int(out_i[k]):8d}\n"
            )
    print("成功產生 debug.txt！可對照 Verdi 裡面 RegFile 的數值。")

    # 4. 生成 golden.txt
    # 前兩欄：Python bit-true hardware golden
    # 後兩欄：floating theory scaled by HW_GAIN，用於 MSE / reference
    res_float = theoretical_eigen_dfrft(x_real, x_imag, TEST_KEY)
    res_float_scaled = res_float * HW_GAIN

    with open("../pattern/golden.txt", "w") as f:
        for i in range(N):
            hr_hex = int(out_r[i]) & 0xFFFF
            hi_hex = int(out_i[i]) & 0xFFFF
            tr_bits = realtobits(res_float_scaled[i].real)
            ti_bits = realtobits(res_float_scaled[i].imag)
            f.write(f"{hr_hex:04X} {hi_hex:04X} {tr_bits:016X} {ti_bits:016X}\n")

    print("成功產生 golden.txt 與 input.txt！")


if __name__ == "__main__":
    generate_files()
