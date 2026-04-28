# -*- coding: utf-8 -*-
import argparse
import math
import random
import datetime
from pathlib import Path

import numpy as np
try:
    import matplotlib.pyplot as plt
except ImportError:
    plt = None
from PIL import Image

# --- System Constants ---
M = 2**32 + 1
J = 2**16
N = 32
# 將量化尺度稍微調降，以確保在軟體模擬中，經過多次乘法後的數值
# 較不容易產生破壞性的截斷誤差，從而提高解密還原的視覺品質。
Q_SCALE = 128.0  

def mod_add(a, b): return (a + b) % M
def mod_sub(a, b): return (a - b) % M
def mod_mul(a, b): return (int(a) * int(b)) % M

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

def ifnt_32_unnormalized(X, root=4):
    inv_root = M - 2**30 
    x = np.zeros(N, dtype=np.int64)
    for k in range(N):
        for n in range(N):
            wk = pow(int(inv_root), k * n, M)
            x[k] = mod_add(x[k], mod_mul(X[n], wk))
    return x 

def generate_chirps(alpha):
    t = np.arange(-16, 16)
    
    # 防止 alpha 為 0 導致的除以零錯誤
    if np.abs(np.sin(alpha)) < 1e-10:
        alpha += 1e-10

    c1 = np.exp(-1j * np.pi * (t**2) * np.tan(alpha / 2))
    
    A_alpha = np.sqrt((1 - 1j / np.tan(alpha)) / (2 * np.pi))
    c2 = A_alpha * np.exp(1j * np.pi * (t**2) / np.sin(alpha))
    
    c1_r, c1_i = np.round(c1.real * Q_SCALE), np.round(c1.imag * Q_SCALE)
    c2_r, c2_i = np.round(c2.real * Q_SCALE), np.round(c2.imag * Q_SCALE)
    
    c1_p1, c1_p2 = complex_to_scc(c1_r, c1_i)
    c2_p1, c2_p2 = complex_to_scc(c2_r, c2_i)
    
    C2_p1 = fnt_32(c2_p1)
    C2_p2 = fnt_32(c2_p2)
    
    return c1_p1, c1_p2, C2_p1, C2_p2

def frft_1d(x_real, x_imag, chirps):
    c1_p1, c1_p2, C2_p1, C2_p2 = chirps
    
    x_p1, x_p2 = complex_to_scc(x_real, x_imag)
    
    p1 = np.array([mod_mul(x_p1[i], c1_p1[i]) for i in range(N)])
    p2 = np.array([mod_mul(x_p2[i], c1_p2[i]) for i in range(N)])
    
    P1 = fnt_32(p1)
    P2 = fnt_32(p2)
    
    P1 = np.array([mod_mul(P1[i], C2_p1[i]) for i in range(N)])
    P2 = np.array([mod_mul(P2[i], C2_p2[i]) for i in range(N)])
    
    p1_conv = ifnt_32_unnormalized(P1)
    p2_conv = ifnt_32_unnormalized(P2)
    
    out_p1 = np.array([mod_mul(p1_conv[i], c1_p1[i]) for i in range(N)])
    out_p2 = np.array([mod_mul(p2_conv[i], c1_p2[i]) for i in range(N)])
    
    neg_2_31 = M - 2**31
    neg_2_15 = M - 2**15
    inv_32 = M - 2**27 
    
    real_out = np.zeros(N, dtype=np.int64)
    imag_out = np.zeros(N, dtype=np.int64)
    
    for i in range(N):
        sum_p = mod_add(out_p1[i], out_p2[i])
        r = mod_mul(sum_p, neg_2_31)
        real_out[i] = mod_mul(r, inv_32)
        
        diff_p = mod_sub(out_p1[i], out_p2[i])
        im = mod_mul(diff_p, neg_2_15)
        imag_out[i] = mod_mul(im, inv_32)
        
    return real_out, imag_out


def frft_1d_debug(x_real, x_imag, chirps):
    """Return all stage intermediates for debug golden dump."""
    c1_p1, c1_p2, C2_p1, C2_p2 = chirps
    x_p1, x_p2 = complex_to_scc(x_real, x_imag)

    # MUL1
    p1_mul1 = np.array([mod_mul(x_p1[i], c1_p1[i]) for i in range(N)], dtype=np.int64)
    p2_mul1 = np.array([mod_mul(x_p2[i], c1_p2[i]) for i in range(N)], dtype=np.int64)

    # FNT
    p1_fnt = fnt_32(p1_mul1)
    p2_fnt = fnt_32(p2_mul1)

    # MUL2
    p1_mul2 = np.array([mod_mul(p1_fnt[i], C2_p1[i]) for i in range(N)], dtype=np.int64)
    p2_mul2 = np.array([mod_mul(p2_fnt[i], C2_p2[i]) for i in range(N)], dtype=np.int64)

    # IFNT
    p1_ifnt = ifnt_32_unnormalized(p1_mul2)
    p2_ifnt = ifnt_32_unnormalized(p2_mul2)

    # MUL3
    p1_mul3 = np.array([mod_mul(p1_ifnt[i], c1_p1[i]) for i in range(N)], dtype=np.int64)
    p2_mul3 = np.array([mod_mul(p2_ifnt[i], c1_p2[i]) for i in range(N)], dtype=np.int64)

    # DEC
    neg_2_31 = M - 2**31
    neg_2_15 = M - 2**15
    inv_32 = M - 2**27
    dec_real = np.zeros(N, dtype=np.int64)
    dec_imag = np.zeros(N, dtype=np.int64)
    for i in range(N):
        sum_p = mod_add(p1_mul3[i], p2_mul3[i])
        diff_p = mod_sub(p1_mul3[i], p2_mul3[i])
        dec_real[i] = mod_mul(mod_mul(sum_p, neg_2_31), inv_32)
        dec_imag[i] = mod_mul(mod_mul(diff_p, neg_2_15), inv_32)

    return {
        "mul1_path1": p1_mul1, "mul1_path2": p2_mul1,
        "fnt_path1": p1_fnt, "fnt_path2": p2_fnt,
        "mul2_path1": p1_mul2, "mul2_path2": p2_mul2,
        "ifnt_path1": p1_ifnt, "ifnt_path2": p2_ifnt,
        "mul3_path1": p1_mul3, "mul3_path2": p2_mul3,
        "dec_real": dec_real, "dec_imag": dec_imag,
    }

def frft_2d(image_real, image_imag, alpha):
    img_real = np.copy(image_real).astype(np.int64)
    img_imag = np.copy(image_imag).astype(np.int64)
    
    chirps = generate_chirps(alpha)
    
    # Row-wise
    for i in range(N):
        img_real[i, :], img_imag[i, :] = frft_1d(img_real[i, :], img_imag[i, :], chirps)
        
    # Column-wise
    for j in range(N):
        img_real[:, j], img_imag[:, j] = frft_1d(img_real[:, j], img_imag[:, j], chirps)
        
    return img_real, img_imag

def process_rgb_channel(channel_data, alpha):
    # Encrypt
    enc_real, enc_imag = frft_2d(channel_data, np.zeros_like(channel_data), alpha)
    # Decrypt (using negative alpha)
    dec_real, _ = frft_2d(enc_real, enc_imag, -alpha)
    return enc_real, dec_real

def normalize_to_8bit(data):
    # Min-max normalization mapping back to 0-255 for visualization
    data_min = np.min(data)
    data_max = np.max(data)
    if data_max == data_min:
        return np.zeros_like(data, dtype=np.uint8)
    norm = (data - data_min) / (data_max - data_min) * 255.0
    return norm.astype(np.uint8)

def theoretical_frft_1d(x, alpha):
    """
    使用標準浮點數運算計算基於 Chirp 卷積的離散 FrFT
    """
    N = len(x)
    t = np.arange(-N//2, N//2) # 對應你程式中的 -16 到 15
    
    # 防止 alpha 為 0
    if np.abs(np.sin(alpha)) < 1e-10:
        alpha += 1e-10

    # 產生未量化的理論 Chirp 訊號
    c1 = np.exp(-1j * np.pi * (t**2) * np.tan(alpha / 2))
    A_alpha = np.sqrt((1 - 1j / np.tan(alpha)) / (2 * np.pi))
    c2 = A_alpha * np.exp(1j * np.pi * (t**2) / np.sin(alpha))

    # 使用浮點數 FFT 計算循環卷積 (模擬 FNT/IFNT 的行為)
    x_c1 = x * c1
    conv_res = np.fft.ifft(np.fft.fft(x_c1) * np.fft.fft(c2))
    
    return conv_res * c1

# --- 2. 有限體數值解碼 ---
def decode_mod(val, M):
    """將有限體 M 上的正數映射回實際的正負浮點數"""
    return val if val < M/2 else val - M


def decode_mod_signed_raw(val):
    x = int(val)
    return x if x < M // 2 else x - M


def write_hex_lines(path, values, width):
    with open(path, "w") as f:
        for v in values:
            f.write(f"{int(v) & ((1 << (4 * width)) - 1):0{width}x}\n")


def write_stage_hex(path, values):
    # F_q range is [0, 2^32], so use 9 hex digits.
    with open(path, "w") as f:
        for v in values:
            f.write(f"{int(v) & 0x1FFFFFFFF:09x}\n")


def write_debug_stages_txt(path, in_words, dbg):
    """Write stage dump in debug_stages.txt-like human-readable format."""
    with open(path, "w") as f:
        f.write("// FrFT Debug Stages Log\n")
        f.write(f"// Generated: {datetime.datetime.now().strftime('%Y.%m.%d')}\n")
        f.write("// Author: sim.py auto dump\n\n")

        def write_block(title, arr):
            f.write(f"[{title}]\n")
            for i, v in enumerate(arr):
                vv = int(v) & 0x1FFFFFFFF
                f.write(f"  idx {i:2d}: {vv:09x} ({int(v)})\n")
            f.write("\n")

        # PATH1 section
        f.write("=== PATH1 DEBUG ===\n")
        input_ferm_path1 = []
        for w in in_words:
            real8 = w & 0xFF
            imag8 = (w >> 8) & 0xFF
            r = real8 if real8 < 0x80 else real8 - 0x100
            im = imag8 if imag8 < 0x80 else imag8 - 0x100
            input_ferm_path1.append((r + (J * im)) % M)
        write_block("Input_Fermat", input_ferm_path1)
        write_block("S_MUL1", dbg["mul1_path1"])
        write_block("S_FFNT_BR", dbg["fnt_path1"])
        write_block("S_MUL2_BR", dbg["mul2_path1"])
        write_block("S_IFNT", dbg["ifnt_path1"])
        write_block("S_MUL3", dbg["mul3_path1"])
        write_block("S_DEC_REAL", dbg["dec_real"])
        write_block("S_DEC_IMAG", dbg["dec_imag"])

        # PATH2 section
        f.write("=== PATH2 DEBUG ===\n")
        input_ferm_path2 = []
        for w in in_words:
            real8 = w & 0xFF
            imag8 = (w >> 8) & 0xFF
            r = real8 if real8 < 0x80 else real8 - 0x100
            im = imag8 if imag8 < 0x80 else imag8 - 0x100
            input_ferm_path2.append((r - (J * im)) % M)
        write_block("Input_Fermat", input_ferm_path2)
        write_block("S_MUL1", dbg["mul1_path2"])
        write_block("S_FFNT_BR", dbg["fnt_path2"])
        write_block("S_MUL2_BR", dbg["mul2_path2"])
        write_block("S_IFNT", dbg["ifnt_path2"])
        write_block("S_MUL3", dbg["mul3_path2"])


def gen_tb_gt_from_sim(alpha, outdir, key=None, random_alpha=False, seed=None, dump_stages=False):
    if random_alpha:
        if seed is not None:
            random.seed(seed)
        margin = 1e-3
        alpha = random.uniform(margin, math.pi - margin)

    if key is None:
        key = int(round((alpha / math.pi) * 255.0)) & 0xFF

    outdir = Path(outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    # same default payload pattern used by TB
    in_words = []
    for k in range(32):
        real8 = k & 0xFF
        imag8 = (0xFF - k) & 0xFF
        in_words.append((imag8 << 8) | real8)  # [15:8]=img, [7:0]=real

    x_real = np.array([((w & 0xFF) if (w & 0x80) == 0 else (w & 0xFF) - 256) for w in in_words], dtype=np.int64)
    x_imag = np.array([(((w >> 8) & 0xFF) if ((w >> 15) & 1) == 0 else ((w >> 8) & 0xFF) - 256) for w in in_words], dtype=np.int64)

    chirps = generate_chirps(alpha)
    out_r, out_i = frft_1d(x_real, x_imag, chirps)
    dbg = frft_1d_debug(x_real, x_imag, chirps) if dump_stages else None

    out_words = []
    out_float = []
    total_q_scale = Q_SCALE ** 3
    for i in range(32):
        r_raw = decode_mod_signed_raw(out_r[i])
        i_raw = decode_mod_signed_raw(out_i[i])
        # no clipping: keep raw signed value and wrap to 16-bit two's complement
        r16 = r_raw & 0xFFFF
        i16 = i_raw & 0xFFFF
        out_words.append((i16 << 16) | r16)
        out_float.append((float(r_raw) / total_q_scale, float(i_raw) / total_q_scale))

    pre_hi = 0xA55A
    pre_lo = 0x5AA5
    in_frame_bytes = [0x00, key & 0xFF, (pre_hi >> 8) & 0xFF, pre_hi & 0xFF, (pre_lo >> 8) & 0xFF, pre_lo & 0xFF]
    for w in in_words:
        in_frame_bytes += [(w >> 8) & 0xFF, w & 0xFF]

    out_frame_bytes = [(pre_hi >> 8) & 0xFF, pre_hi & 0xFF, (pre_lo >> 8) & 0xFF, pre_lo & 0xFF]
    for w in out_words:
        out_frame_bytes += [(w >> 24) & 0xFF, (w >> 16) & 0xFF, (w >> 8) & 0xFF, w & 0xFF]

    write_hex_lines(outdir / "input_words_32.hex", in_words, 4)
    write_hex_lines(outdir / "output_words_32.hex", out_words, 8)
    write_hex_lines(outdir / "input_frame_bytes.hex", in_frame_bytes, 2)
    write_hex_lines(outdir / "output_frame_bytes.hex", out_frame_bytes, 2)
    write_hex_lines(outdir / "key.hex", [key], 2)
    with open(outdir / "alpha.txt", "w") as f:
        f.write(f"{alpha:.18f}\n")
    with open(outdir / "output_float_32.txt", "w") as f:
        for rr, ii in out_float:
            f.write(f"{rr:.6f} {ii:.6f}\n")

    if dump_stages:
        stage_dir = outdir / "stages"
        stage_dir.mkdir(parents=True, exist_ok=True)
        for name, arr in dbg.items():
            write_stage_hex(stage_dir / f"{name}.hex", arr)
        write_debug_stages_txt(outdir / "debug_stages.txt", in_words, dbg)

    print(f"Generated GT at: {outdir}")
    print(f"alpha={alpha:.12f}, key=0x{key:02x}")
    print("Files: input_words_32.hex output_words_32.hex input_frame_bytes.hex output_frame_bytes.hex key.hex alpha.txt output_float_32.txt")
    if dump_stages:
        print("Stage files: stages/*.hex and debug_stages.txt")


# --- 執行 1D 比對測試 ---
# --- 執行 1D 比對測試 (複數輸入) ---
if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--gen-gt", action="store_true", help="Generate TB GT files from sim model and exit.")
    ap.add_argument("--alpha", type=float, default=np.pi / 4)
    ap.add_argument("--key", type=int, default=None)
    ap.add_argument("--random-alpha", action="store_true")
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--outdir", type=str, default="pattern/gt_2path")
    ap.add_argument("--dump-stages", action="store_true")
    args = ap.parse_args()

    if args.gen_gt:
        gen_tb_gt_from_sim(
            alpha=args.alpha,
            outdir=args.outdir,
            key=args.key,
            random_alpha=args.random_alpha,
            seed=args.seed,
            dump_stages=args.dump_stages
        )
        raise SystemExit(0)

    if plt is None:
        print("matplotlib is not installed. Use --gen-gt mode or install matplotlib.")
        raise SystemExit(1)

    print("--- Starting 1D FrFT Verification (Complex Input) ---")
    
    alpha_param = np.pi / 4
    
    # 建立測試訊號 (加入實部與虛部)
    t_n = np.arange(32)
    real_part = 100 * np.tanh(2 * np.pi * t_n / 32)
    imag_part = 50 * np.sin(4 * np.pi * t_n / 32)  # 加入一個正弦波作為虛部
    
    # 組合為浮點數複數與分離的整數實部/虛部
    x_float = real_part + 1j * imag_part
    x_int_real = np.round(x_float.real).astype(np.int64)
    x_int_imag = np.round(x_float.imag).astype(np.int64)
    
    # =========================
    # [1] 理論 FrFT (+alpha, -alpha)
    # =========================
    float_result_pos = theoretical_frft_1d(x_float, alpha_param)
    float_result_neg = theoretical_frft_1d(x_float, -alpha_param)
    
    # =========================
    # [2] FNT FrFT (+alpha)
    # =========================
    chirps_pos = generate_chirps(alpha_param)
    # 這裡把 x_int_real 和 x_int_imag 都傳進去了
    fnt_r_pos, fnt_i_pos = frft_1d(x_int_real, x_int_imag, chirps_pos)
    
    # =========================
    # [3] FNT FrFT (-alpha)
    # =========================
    chirps_neg = generate_chirps(-alpha_param)
    fnt_r_neg, fnt_i_neg = frft_1d(x_int_real, x_int_imag, chirps_neg)
    
    # =========================
    # [4] decode function
    # =========================
    def recover_complex(fnt_r, fnt_i):
        fnt_r_decoded = np.array([decode_mod(v, M) for v in fnt_r], dtype=float)
        fnt_i_decoded = np.array([decode_mod(v, M) for v in fnt_i], dtype=float)
        
        total_q_scale = Q_SCALE ** 3
        return (fnt_r_decoded + 1j * fnt_i_decoded) / total_q_scale
    
    fnt_complex_pos = recover_complex(fnt_r_pos, fnt_i_pos)
    fnt_complex_neg = recover_complex(fnt_r_neg, fnt_i_neg)
    
    # =========================
    # [5] error
    # =========================
    error_pos = np.abs(float_result_pos - fnt_complex_pos)
    error_neg = np.abs(float_result_neg - fnt_complex_neg)
    
    print("\n--- +alpha ---")
    print(f"MSE: {np.mean(error_pos**2):.6f}")
    print(f"Max Error: {np.max(error_pos):.6f}")
    
    print("\n--- -alpha ---")
    print(f"MSE: {np.mean(error_neg**2):.6f}")
    print(f"Max Error: {np.max(error_neg):.6f}")
    
    # =========================
    # [6] visualization
    # =========================
    fig, axes = plt.subplots(3, 1, figsize=(10, 12))
    
    # Input signal (現在包含 Real 和 Imag 兩條線)
    axes[0].plot(t_n, x_float.real, label="Input Real", marker='o')
    axes[0].plot(t_n, x_float.imag, label="Input Imag", marker='x', linestyle='--')
    axes[0].set_title("Complex Input Signal")
    axes[0].legend()
    axes[0].grid(True, linestyle=':')
    
    # Real part comparison
    axes[1].plot(t_n, float_result_pos.real, label="+α Theoretical", marker='o')
    axes[1].plot(t_n, fnt_complex_pos.real, '--', label="+α FNT", marker='x')
    axes[1].plot(t_n, float_result_neg.real, label="-α Theoretical", marker='s')
    axes[1].plot(t_n, fnt_complex_neg.real, '--', label="-α FNT", marker='d')
    axes[1].set_title("Real Part Comparison")
    axes[1].legend()
    axes[1].grid(True, linestyle=':')
    
    # Imag part comparison
    axes[2].plot(t_n, float_result_pos.imag, label="+α Theoretical", marker='o')
    axes[2].plot(t_n, fnt_complex_pos.imag, '--', label="+α FNT", marker='x')
    axes[2].plot(t_n, float_result_neg.imag, label="-α Theoretical", marker='s')
    axes[2].plot(t_n, fnt_complex_neg.imag, '--', label="-α FNT", marker='d')
    axes[2].set_title("Imaginary Part Comparison")
    axes[2].legend()
    axes[2].grid(True, linestyle=':')
    
    plt.tight_layout()
    plt.show()

'''
# --- Execution & Visualization ---
if __name__ == "__main__":
    # 建立一個測試用的隨機 RGB 圖片，實務上可替換為 PIL 讀取外部圖檔
    # 例如: img = Image.open("your_image.jpg").convert('RGB').resize((32, 32))
    # input_img_array = np.array(img)
    
    # 這裡先自動生成一個具備幾何特徵的測試圖以便觀察
    test_img = np.zeros((32, 32, 3), dtype=np.uint8)
    test_img[8:24, 8:24, 0] = 255  # Red square
    test_img[12:28, 12:28, 1] = 200 # Green square
    test_img[4:20, 16:30, 2] = 150 # Blue square
    
    alpha_param = np.pi / 4 
    
    enc_img = np.zeros((32, 32, 3), dtype=np.uint8)
    dec_img = np.zeros((32, 32, 3), dtype=np.uint8)
    
    print(f"Processing 32x32 RGB Image with alpha = {alpha_param:.4f}...")
    
    for c in range(3):
        print(f"Processing channel {c+1}/3...")
        enc_r, dec_r = process_rgb_channel(test_img[:, :, c], alpha_param)
        
        enc_img[:, :, c] = normalize_to_8bit(enc_r)
        dec_img[:, :, c] = normalize_to_8bit(dec_r)

    print("Processing complete. Generating visualization...")

    # 使用明確的 axis 指定，確保索引映射安全
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    
    axes[0].imshow(test_img)
    axes[0].set_title("Original Image (32x32)")
    axes[0].axis('off')
    
    axes[1].imshow(enc_img)
    axes[1].set_title(f"Encrypted (alpha = {alpha_param:.2f})")
    axes[1].axis('off')
    
    axes[2].imshow(dec_img)
    axes[2].set_title(f"Decrypted (alpha = {-alpha_param:.2f})")
    axes[2].axis('off')
    
    plt.tight_layout()
    plt.show()
    plt.savefig('test.png')
'''