import numpy as np
import scipy.linalg as la
import matplotlib.pyplot as plt
import math
from tqdm import tqdm
from PIL import Image
import argparse

# ==========================================
# 硬體系統常數與 Bit-width 設定
# ==========================================
N = 32
V_BITS = 14       # 矩陣 V 的小數點位數 (Q14)
S1_SHIFT = 10     # Stage 1 算完後的右移量
S2_SHIFT = 10     # Stage 2 (CORDIC 旋轉) 算完後的右移量
S3_SHIFT = 17     # Stage 3 算完後的最終右移量

# Shift-and-Add 限制
MAX_TERMS = 2     # 👉 硬體限制：每個常數最多由幾個 2 的次方相加減組成 (決定 Adder 數量)

# CORDIC 參數
STAGES = 11
OUTPUT_SHIFT = 5
def get_k_inv(stages, frac_bits=14):
    K = 1.0
    for i in range(stages):
        K *= math.sqrt(1 + 2**(-2*i))
    return int(round((1 << frac_bits) / K))

K_INV = get_k_inv(STAGES)
ATAN_TABLE_FULL = [8192, 4836, 2555, 1297, 651, 326, 163, 81, 41, 20, 10, 5]
ATAN_TABLE = ATAN_TABLE_FULL[:STAGES]

# ==========================================
# 輔助函式：模擬 Verilog 截斷與符號
# ==========================================
def to_signed(val, bits):
    val = int(val) & ((1 << bits) - 1)
    if val >= (1 << (bits - 1)):
        val -= (1 << bits)
    return val

def hw_cordic(phase_in):
    phase_in = to_signed(phase_in, 16)
    if phase_in > 16384 or phase_in < -16384:
        x, y = -K_INV, 0
        z = to_signed(phase_in - 32768 if phase_in > 0 else phase_in + 32768, 16)
    else:
        x, y = K_INV, 0
        z = phase_in

    for i in range(STAGES):
        sign = (z < 0)
        x_shift, y_shift = x >> i, y >> i
        if not sign:
            x_next, y_next, z_next = x - y_shift, y + x_shift, z - ATAN_TABLE[i]
        else:
            x_next, y_next, z_next = x + y_shift, y - x_shift, z + ATAN_TABLE[i]
        x, y, z = to_signed(x_next, 16), to_signed(y_next, 16), to_signed(z_next, 16)

    def extract_and_round(val):
        val_unsigned = val & 0xFFFF
        out_bits = 16 - OUTPUT_SHIFT
        main_mask = (1 << out_bits) - 1
        main = (val_unsigned >> OUTPUT_SHIFT) & main_mask
        round_bit = (val_unsigned >> (OUTPUT_SHIFT - 1)) & 1
        return to_signed((main + round_bit) & main_mask, out_bits)
    
    return extract_and_round(x), extract_and_round(y)

# ==========================================
# 矩陣 V 的生成與 CSD (Shift-and-Add) 量化
# ==========================================
def approx_pot_csd(val_int, num_terms):
    if val_int == 0: return 0
    residual = val_int
    res_val = 0
    for _ in range(num_terms):
        if residual == 0: break
        sign = 1 if residual > 0 else -1
        abs_res = abs(residual)
        p = int(round(math.log2(abs_res)))
        res_val += sign * (1 << p)
        residual -= sign * (1 << p)
    return res_val

def get_ultimate_V_and_k(N):
    S = np.zeros((N, N))
    for n in range(N):
        S[n, n] = 2 * np.cos(2 * np.pi * n / N)
        S[n, (n + 1) % N] = 1; S[n, (n - 1) % N] = 1
    J = np.zeros((N, N)); J[0, 0] = 1
    for i in range(1, N): J[i, N - i] = 1
        
    S_prime = S + 1e-6 * J 
    eig_vals, eig_vecs = la.eigh(S_prime)
    n_idx = np.arange(N)
    F = np.exp(-2j * np.pi * np.outer(n_idx, n_idx) / N) / np.sqrt(N)
    buckets = {0: [], 1: [], 2: [], 3: []}
    ideal_eigvals = [1, -1j, -1, 1j]
    
    for i in range(N):
        v = eig_vecs[:, i]
        v_cyclic = np.append(v, v[0])
        z_count = np.where(np.diff(np.sign(v_cyclic + 1e-15)))[0].size
        dft_type = np.argmin([np.abs(np.vdot(v, F @ v) - val) for val in ideal_eigvals])
        buckets[dft_type].append((z_count, i))
        
    for t in buckets: buckets[t].sort(key=lambda x: x[0])
    k_orders = np.arange(N)
    if N % 2 == 0: k_orders[-1] = N
        
    sorted_indices = []
    for k in k_orders:
        req_type = k % 4
        if buckets[req_type]: sorted_indices.append(buckets[req_type].pop(0)[1])
            
    V = eig_vecs[:, sorted_indices]
    for i in range(N):
        if V[np.argmax(np.abs(V[:, i])), i] < 0: V[:, i] *= -1
    return V, k_orders

V_float, k_orders = get_ultimate_V_and_k(N)
V_q = np.zeros((N, N), dtype=np.int64)
for i in range(N):
    for j in range(N):
        val_int = int(round(V_float[i, j] * (1 << V_BITS)))
        V_q[i, j] = approx_pot_csd(val_int, num_terms=MAX_TERMS)

# ==========================================
# 1D 硬體管線模型
# ==========================================
def theoretical_eigen_dfrft(x_real, x_imag, key):
    angle_param = key * np.pi / 128
    x_c = x_real + 1j * x_imag
    phi = - k_orders * angle_param
    Lambda_alpha = np.exp(1j * phi)
    result = V_float @ (Lambda_alpha * (V_float.T @ x_c))
    return result.real, result.imag

def hw_dfrft_pipeline_1d(x_real, x_imag, key):
    # [Stage 1: V^T * x] 
    y1_r_full, y1_i_full = np.zeros(N, dtype=np.int64), np.zeros(N, dtype=np.int64)
    for k in range(N):
        for n in range(N):
            y1_r_full[k] += V_q[n, k] * x_real[n]
            y1_i_full[k] += V_q[n, k] * x_imag[n]
            
    y1_r_q = (y1_r_full + (1 << (S1_SHIFT - 1))) >> S1_SHIFT
    y1_i_q = (y1_i_full + (1 << (S1_SHIFT - 1))) >> S1_SHIFT

    # [Stage 2: CORDIC]
    y2_r_full, y2_i_full = np.zeros(N, dtype=np.int64), np.zeros(N, dtype=np.int64)
    for k in range(N):
        phase_val = to_signed(-256 * k_orders[k] * key, 16)
        c_cos, c_sin = hw_cordic(phase_val)
        y2_r_full[k] = y1_r_q[k] * c_cos - y1_i_q[k] * c_sin
        y2_i_full[k] = y1_r_q[k] * c_sin + y1_i_q[k] * c_cos

    y2_r_q = (y2_r_full + (1 << (S2_SHIFT - 1))) >> S2_SHIFT
    y2_i_q = (y2_i_full + (1 << (S2_SHIFT - 1))) >> S2_SHIFT

    # [Stage 3: V * y2]
    y3_r_full, y3_i_full = np.zeros(N, dtype=np.int64), np.zeros(N, dtype=np.int64)
    for n in range(N):
        for k in range(N):
            y3_r_full[n] += V_q[n, k] * y2_r_q[k]
            y3_i_full[n] += V_q[n, k] * y2_i_q[k]

    out_r = (y3_r_full + (1 << (S3_SHIFT - 1))) >> S3_SHIFT
    out_i = (y3_i_full + (1 << (S3_SHIFT - 1))) >> S3_SHIFT
    return out_r, out_i

# ==========================================
# 2D 影像處理擴充模組 (Row-Column 分離運算)
# ==========================================
def dfrft_2d_hw(img_real, img_imag, key):
    """
    執行 2D DFrFT，透過呼叫兩次 1D DFrFT 達成
    """
    row_r = np.zeros((N, N), dtype=np.int64)
    row_i = np.zeros((N, N), dtype=np.int64)
    
    # 1. Row Transform (列轉換)
    for i in range(N):
        r_out, i_out = hw_dfrft_pipeline_1d(img_real[i, :], img_imag[i, :], key)
        #r_out, i_out = theoretical_eigen_dfrft(img_real[i, :], img_imag[i, :], key)
        row_r[i, :] = r_out
        row_i[i, :] = i_out
        
    final_r = np.zeros((N, N), dtype=np.int64)
    final_i = np.zeros((N, N), dtype=np.int64)
    
    # 2. Column Transform (行轉換)
    for j in range(N):
        r_out, i_out = hw_dfrft_pipeline_1d(row_r[:, j], row_i[:, j], key)
        #r_out, i_out = theoretical_eigen_dfrft(row_r[:, j], row_i[:, j], key)
        final_r[:, j] = r_out
        final_i[:, j] = i_out
        
    return final_r, final_i

def normalize_to_8bit(arr):
    """將任意範圍的陣列線性映射到 0~255，供影像顯示使用"""
    arr_f = arr.astype(np.float64)
    arr_min, arr_max = arr_f.min(), arr_f.max()
    if arr_max > arr_min:
        norm = (arr_f - arr_min) / (arr_max - arr_min) * 255.0
    else:
        norm = arr_f - arr_min
    return np.clip(np.round(norm), 0, 255).astype(np.uint8)

# ==========================================
# Block Padding
# ==========================================

def pad_to_block_size(img, block_size=32):

    H, W, C = img.shape

    new_H = ((H + block_size - 1) // block_size) * block_size
    new_W = ((W + block_size - 1) // block_size) * block_size

    padded = np.zeros((new_H, new_W, C), dtype=np.uint8)

    padded[:H, :W] = img

    return padded, H, W

# ==========================================
# Block-wise DFrFT Image Processing
# ==========================================

def process_image_blockwise(img, key, block_size=32):

    padded_img, orig_H, orig_W = pad_to_block_size(img, block_size)

    H, W, C = padded_img.shape

    enc_img_vis = np.zeros((H, W, 3), dtype=np.uint8)
    dec_img = np.zeros((H, W, 3), dtype=np.uint8)

    for c in range(3):

        print(f"Processing channel {c+1}/3...")

        for by in range(0, H, block_size):
            for bx in range(0, W, block_size):
                print(f"by:{by}, bx:{bx}")
                # ---------------------------------
                # 取 32x32 block
                # ---------------------------------

                block = padded_img[
                    by:by+block_size,
                    bx:bx+block_size,
                    c
                ]

                # uint8 -> signed
                ch_in_r = block.astype(np.int64) - 128
                ch_in_i = np.zeros((N, N), dtype=np.int64)

                # ---------------------------------
                # Encrypt
                # ---------------------------------

                enc_r, enc_i = dfrft_2d_hw(
                    ch_in_r,
                    ch_in_i,
                    key
                )

                # magnitude visualization
                magnitude = np.sqrt(enc_r**2 + enc_i**2)

                enc_img_vis[
                    by:by+block_size,
                    bx:bx+block_size,
                    c
                ] = normalize_to_8bit(magnitude)

                # ---------------------------------
                # Decrypt
                # ---------------------------------

                dec_r, dec_i = dfrft_2d_hw(
                    enc_r,
                    enc_i,
                    -key
                )

                recon_pixel = dec_r + 128

                dec_img[
                    by:by+block_size,
                    bx:bx+block_size,
                    c
                ] = np.clip(recon_pixel, 0, 255).astype(np.uint8)

    # crop 回原圖大小
    enc_img_vis = enc_img_vis[:orig_H, :orig_W]
    dec_img = dec_img[:orig_H, :orig_W]

    return enc_img_vis, dec_img

# ==========================================
# 主程式：2D 影像加密與解密測試
# ==========================================
if __name__ == "__main__":

    # ======================================
    # Argument Parser
    # ======================================

    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--img_path",
        type=str,
        default=None,
        help="External image path"
    )

    args = parser.parse_args()

    # ======================================
    # Settings
    # ======================================

    encrypt_key = 32

    # ======================================
    # Image Source
    # ======================================

    if args.img_path is None:

        print("Using built-in 32x32 test pattern...")

        # 原本內建測試圖
        test_img = np.zeros((32, 32, 3), dtype=np.uint8)

        test_img[8:24, 8:24, 0] = 255
        test_img[12:28, 12:28, 1] = 200
        test_img[4:20, 16:30, 2] = 150

        use_block_mode = False

    else:

        print(f"Loading external image: {args.img_path}")

        img = Image.open(args.img_path).convert("RGB")

        test_img = np.array(img, dtype=np.uint8)

        use_block_mode = True

    H, W, _ = test_img.shape

    print(f"Image Size      = {H} x {W}")
    print(f"Encryption Key  = {encrypt_key}")

    # ======================================
    # Processing
    # ======================================

    if not use_block_mode:

        # ==================================
        # 原本 32x32 單次處理
        # ==================================

        enc_img_vis = np.zeros((32, 32, 3), dtype=np.uint8)
        dec_img = np.zeros((32, 32, 3), dtype=np.uint8)

        for c in range(3):

            print(f"Processing channel {c+1}/3...")

            ch_in_r = test_img[:, :, c].astype(np.int64) - 128
            ch_in_i = np.zeros((N, N), dtype=np.int64)

            enc_r, enc_i = dfrft_2d_hw(
                ch_in_r,
                ch_in_i,
                encrypt_key
            )

            magnitude = np.sqrt(enc_r**2 + enc_i**2)

            enc_img_vis[:, :, c] = normalize_to_8bit(magnitude)

            dec_r, dec_i = dfrft_2d_hw(
                enc_r,
                enc_i,
                -encrypt_key
            )

            recon_pixel = dec_r + 128

            dec_img[:, :, c] = np.clip(
                recon_pixel,
                0,
                255
            ).astype(np.uint8)

    else:

        # ==================================
        # Block-wise mode
        # ==================================

        enc_img_vis, dec_img = process_image_blockwise(
            test_img,
            encrypt_key,
            block_size=N
        )

    print("Processing complete.")

    # ======================================
    # MSE
    # ======================================

    mse = np.mean(
        (test_img.astype(np.float64)
        - dec_img.astype(np.float64))**2
    )

    print(f"Decryption Image MSE: {mse:.6f}")

    # ======================================
    # Visualization
    # ======================================

    fig, axes = plt.subplots(1, 3, figsize=(18, 6))

    axes[0].imshow(test_img)
    axes[0].set_title("1. Original")
    axes[0].axis('off')

    axes[1].imshow(enc_img_vis)
    axes[1].set_title(f"2. Encrypted (Key={encrypt_key})")
    axes[1].axis('off')

    axes[2].imshow(dec_img)
    axes[2].set_title("3. Decrypted")
    axes[2].axis('off')

    plt.tight_layout()

    plt.savefig("2d_encryption_test.png", dpi=300)

    plt.show()