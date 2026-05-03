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

# --- System Constants ---
M = 2**32 + 1
J = 2**16
N = 32
Q_SCALE_1 = 64.0
Q_SCALE_2 = 32.0  
NUM_PATTERNS = 5
KEY_INC = 10     # base key + KEY_INC * n

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
    if np.abs(np.sin(alpha)) < 1e-10:
        alpha += 1e-10

    c1 = np.exp(-1j * np.pi * (t**2) * np.tan(alpha / 2))
    A_alpha = np.sqrt((1 - 1j / np.tan(alpha)) / (2 * np.pi))
    c2 = A_alpha * np.exp(1j * np.pi * (t**2) / np.sin(alpha))
    
    c1_r, c1_i = np.round(c1.real * Q_SCALE_1), np.round(c1.imag * Q_SCALE_1)
    c2_r, c2_i = np.round(c2.real * Q_SCALE_2), np.round(c2.imag * Q_SCALE_2)
    
    # 【模擬硬體的 t=0 寫死 Bug】
    # t=0 對應陣列的 index 16
    c1_r[16] = Q_SCALE_1
    c1_i[16] = 0
    c2_r[16] = Q_SCALE_2
    c2_i[16] = 0
    
    c1_p1, c1_p2 = complex_to_scc(c1_r, c1_i)
    c2_p1, c2_p2 = complex_to_scc(c2_r, c2_i)
    C2_p1 = fnt_32(c2_p1)
    C2_p2 = fnt_32(c2_p2)
    return c1_p1, c1_p2, C2_p1, C2_p2, c1_r, c1_i, c2_r, c2_i

# --- 有限體數值解碼 ---
def decode_mod(val, M):
    return val if val < M/2 else val - M

def frft_1d(x_real, x_imag, chirps):
    c1_p1, c1_p2, C2_p1, C2_p2, _, _, _, _ = chirps
    
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
    pos_2_15 = 2**15
    inv_32 = M - 2**27 

    K_r = (neg_2_31 * inv_32) % M
    K_i_pos = (neg_2_15 * inv_32) % M
    K_i_neg = (pos_2_15 * inv_32) % M

    real_out = np.zeros(N, dtype=np.int64)
    imag_out = np.zeros(N, dtype=np.int64)
    
    for i in range(N):
        shift = int(np.ceil(np.log2(Q_SCALE_1*Q_SCALE_1*Q_SCALE_2)))

        real_out[i] = mod_add(mod_mul(out_p1[i], K_r), mod_mul(out_p2[i], K_r))
        real_out[i] = decode_mod(real_out[i], M)
        real_out[i] = real_out[i] >> shift

        imag_out[i] = mod_add(mod_mul(out_p1[i], K_i_pos), mod_mul(out_p2[i], K_i_neg))
        imag_out[i] = decode_mod(imag_out[i], M)
        imag_out[i] = imag_out[i] >> shift

    return real_out, imag_out


def frft_1d_debug(x_real, x_imag, chirps):
    """Return all stage intermediates for debug golden dump."""
    c1_p1, c1_p2, C2_p1, C2_p2, c1_r, c1_i, c2_r, c2_i = chirps
    x_p1, x_p2 = complex_to_scc(x_real, x_imag)
    
    # 取出 Chirp 2 在 FNT 之前的 Fermat Field 映射值
    c2_p1_before_fnt, c2_p2_before_fnt = complex_to_scc(c2_r, c2_i)

    p1_mul1 = np.array([mod_mul(x_p1[i], c1_p1[i]) for i in range(N)], dtype=np.int64)
    p2_mul1 = np.array([mod_mul(x_p2[i], c1_p2[i]) for i in range(N)], dtype=np.int64)

    p1_fnt = fnt_32(p1_mul1)
    p2_fnt = fnt_32(p2_mul1)

    p1_mul2 = np.array([mod_mul(p1_fnt[i], C2_p1[i]) for i in range(N)], dtype=np.int64)
    p2_mul2 = np.array([mod_mul(p2_fnt[i], C2_p2[i]) for i in range(N)], dtype=np.int64)

    p1_ifnt = ifnt_32_unnormalized(p1_mul2)
    p2_ifnt = ifnt_32_unnormalized(p2_mul2)

    p1_mul3 = np.array([mod_mul(p1_ifnt[i], c1_p1[i]) for i in range(N)], dtype=np.int64)
    p2_mul3 = np.array([mod_mul(p2_ifnt[i], c1_p2[i]) for i in range(N)], dtype=np.int64)

    neg_2_31 = M - 2**31
    neg_2_15 = M - 2**15
    pos_2_15 = 2**15
    inv_32 = M - 2**27
    
    K_r = (neg_2_31 * inv_32) % M
    K_i_pos = (neg_2_15 * inv_32) % M
    K_i_neg = (pos_2_15 * inv_32) % M

    dout_mul_r_p1 = np.zeros(N, dtype=np.int64)
    dout_mul_r_p2 = np.zeros(N, dtype=np.int64)
    dout_mul_i_p1 = np.zeros(N, dtype=np.int64)
    dout_mul_i_p2 = np.zeros(N, dtype=np.int64)

    dec_real = np.zeros(N, dtype=np.int64)
    dec_imag = np.zeros(N, dtype=np.int64)
    for i in range(N):
        dout_mul_r_p1[i] = mod_mul(p1_mul3[i], K_r)
        dout_mul_r_p2[i] = mod_mul(p2_mul3[i], K_r)
        dout_mul_i_p1[i] = mod_mul(p1_mul3[i], K_i_pos)
        dout_mul_i_p2[i] = mod_mul(p2_mul3[i], K_i_neg)

        dec_real[i] = mod_add(mod_mul(p1_mul3[i], K_r), mod_mul(p2_mul3[i], K_r))
        dec_imag[i] = mod_add(mod_mul(p1_mul3[i], K_i_pos), mod_mul(p2_mul3[i], K_i_neg))

    return {
        "raw_c1_r": c1_r, "raw_c1_i": c1_i,
        "raw_c2_r": c2_r, "raw_c2_i": c2_i,
        "chirp1_path1": c1_p1, "chirp1_path2": c1_p2,
        "chirp2_before_fnt_path1": c2_p1_before_fnt, "chirp2_before_fnt_path2": c2_p2_before_fnt,
        "chirp2_path1": C2_p1, "chirp2_path2": C2_p2,
        "mul1_path1": p1_mul1, "mul1_path2": p2_mul1,
        "fnt_path1": p1_fnt, "fnt_path2": p2_fnt,
        "mul2_path1": p1_mul2, "mul2_path2": p2_mul2,
        "ifnt_path1": p1_ifnt, "ifnt_path2": p2_ifnt,
        "chirp3_path1": c1_p1, "chirp3_path2": c1_p2,
        "mul3_path1": p1_mul3, "mul3_path2": p2_mul3,
        "dout_mul_r_p1": dout_mul_r_p1, "dout_mul_r_p2": dout_mul_r_p2, 
        "dout_mul_i_p1": dout_mul_i_p1, "dout_mul_i_p2": dout_mul_i_p2,
        "dec_real": dec_real, "dec_imag": dec_imag,
    }

def write_hex_lines(path, values, width):
    with open(path, "w") as f:
        for v in values:
            f.write(f"{int(v) & ((1 << (4 * width)) - 1):0{width}x}\n")

def write_stage_hex(path, values):
    with open(path, "w") as f:
        for v in values:
            # 轉換為 dim-1 format: (val - 1) % M
            v_dim1 = (int(v) - 1) % M
            f.write(f"{v_dim1 & 0x1FFFFFFFF:09x}\n")

def write_debug_stages_txt(path, in_words, dbg):
    """Write stage dump in debug_stages.txt-like human-readable format."""
    def bitrev5(x):
            # 5-bit 反轉函式 (用於對齊硬體記憶體位址)
            return int('{:05b}'.format(x)[::-1], 2)
    
    with open(path, "w") as f:
        f.write("// FrFT Debug Stages Log\n")
        f.write(f"// Generated: {datetime.datetime.now().strftime('%Y.%m.%d')}\n")
        f.write("// Format: dim-1 encoding (val - 1) % M and LUT raw hex\n\n")

        def write_block(title, arr):
            f.write(f"[{title}]\n")
            for i, v in enumerate(arr):
                v_dim1 = (int(v) - 1) % M
                vv = v_dim1 & 0x1FFFFFFFF
                f.write(f"  idx {i:2d}: {vv:09x} (dim-1: {v_dim1:<10d} | raw: {int(v)})\n")
            f.write("\n")

        def write_block_br(title, arr):
            f.write(f"[{title} (Bit-Reversed Order mapping to RAM Addr)]\n")
            for i in range(32):
                br_idx = bitrev5(i)
                v = arr[br_idx]
                v_dim1 = (int(v) - 1) % M
                vv = v_dim1 & 0x1FFFFFFFF
                f.write(f"  RAM Addr {i:2d} (logical {br_idx:2d}): {vv:09x} (dim-1: {v_dim1:<10d})\n")
            f.write("\n")

        # 寫出 LUT 格式的 16-bit 拼接值 (不分 path)
        f.write("=== LUT RAW DATA DEBUG (For IO/LUT Interface) ===\n")
        f.write("[LUT_Chirp13_Raw]\n")
        for i in range(N):
            r = int(dbg["raw_c1_r"][i]) & 0xFF
            im = int(dbg["raw_c1_i"][i]) & 0xFF
            val_16b = (im << 8) | r
            f.write(f"  t={i-16:3d} (idx {i:2d}): {val_16b:04x} (real={r:02x}, imag={im:02x})\n")
        f.write("\n")
        
        f.write("[LUT_Chirp2_Raw]\n")
        for i in range(N):
            r = int(dbg["raw_c2_r"][i]) & 0xFF
            im = int(dbg["raw_c2_i"][i]) & 0xFF
            val_16b = (im << 8) | r
            f.write(f"  t={i-16:3d} (idx {i:2d}): {val_16b:04x} (real={r:02x}, imag={im:02x})\n")
        f.write("\n")

        f.write("=== PATH1 DEBUG (Internal Core Data in dim-1) ===\n")
        input_ferm_path1 = []
        for w in in_words:
            real8 = w & 0xFF
            imag8 = (w >> 8) & 0xFF
            r = real8 if real8 < 0x80 else real8 - 0x100
            im = imag8 if imag8 < 0x80 else imag8 - 0x100
            input_ferm_path1.append((r + (J * im)) % M)
            
        write_block("Input_Fermat", input_ferm_path1)
        write_block("Chirp1_Fermat", dbg["chirp1_path1"])
        
        write_block("S_LDCP (Chirp 2 Before FNT in RAM)", dbg["chirp2_before_fnt_path1"])
        write_block_br("S_CFNT_BR (Chirp 2 After FNT in RAM)", dbg["chirp2_path1"])
        
        write_block("S_MUL1", dbg["mul1_path1"])
        write_block_br("S_FFNT_BR", dbg["fnt_path1"])
        write_block_br("S_MUL2_BR", dbg["mul2_path1"])
        write_block("S_IFNT", dbg["ifnt_path1"])
        write_block("Chirp3_Fermat", dbg["chirp3_path1"])
        write_block("S_MUL3", dbg["mul3_path1"])

        f.write("=== PATH2 DEBUG (Internal Core Data in dim-1) ===\n")
        input_ferm_path2 = []
        for w in in_words:
            real8 = w & 0xFF
            imag8 = (w >> 8) & 0xFF
            r = real8 if real8 < 0x80 else real8 - 0x100
            im = imag8 if imag8 < 0x80 else imag8 - 0x100
            input_ferm_path2.append((r - (J * im)) % M)
            
        write_block("Input_Fermat", input_ferm_path2)
        write_block("Chirp1_Fermat", dbg["chirp1_path2"])
        
        write_block("S_LDCP (Chirp 2 Before FNT in RAM)", dbg["chirp2_before_fnt_path2"])
        write_block_br("S_CFNT_BR (Chirp 2 After FNT in RAM)", dbg["chirp2_path2"])
        
        write_block("S_MUL1", dbg["mul1_path2"])
        write_block_br("S_FFNT_BR", dbg["fnt_path2"])
        write_block_br("S_MUL2_BR", dbg["mul2_path2"])
        write_block("S_IFNT", dbg["ifnt_path2"])
        write_block("Chirp3_Fermat", dbg["chirp3_path2"])
        write_block("S_MUL3", dbg["mul3_path2"])

        f.write("=== DECODE S_DOUT DEBUG (Path1 + Path2 Combinations) ===\n")
        f.write("// P1_R: mul_out_1 in Real Decode Cycle (p1_mul3 * REAL_PATH1_SCALE)\n")
        f.write("// P2_R: mul_out_1 in Real Decode Cycle (p2_mul3 * REAL_PATH2_SCALE)\n")
        f.write("// P1_I: mul_out_1 in Imag Decode Cycle (p1_mul3 * IMAG_PATH1_SCALE)\n")
        f.write("// P2_I: mul_out_1 in Imag Decode Cycle (p2_mul3 * IMAG_PATH2_SCALE)\n\n")

        write_block("S_DOUT_P1_Real_Mul", dbg["dout_mul_r_p1"])
        write_block("S_DOUT_P2_Real_Mul", dbg["dout_mul_r_p2"])
        write_block("S_DOUT_P1_Imag_Mul", dbg["dout_mul_i_p1"])
        write_block("S_DOUT_P2_Imag_Mul", dbg["dout_mul_i_p2"])

        write_block("S_DEC_REAL_SUM", dbg["dec_real"])
        write_block("S_DEC_IMAG_SUM", dbg["dec_imag"])

def gen_tb_gt_from_sim(alpha_arg, outdir, key_arg=None, random_alpha=False, seed=None, dump_stages=False):
    if seed is not None:
        random.seed(seed)

    outdir = Path(outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    all_in_words = []
    all_out_words = []
    all_keys = []
    all_out_float = []

    for p in range(NUM_PATTERNS):
        # 每組產生不同的 Key 與 Alpha
        if random_alpha:
            margin = 1e-3
            alpha = random.uniform(margin, math.pi - margin)
            key = int(round((alpha / math.pi) * 128.0)) & 0xFF
        else:
            base_key = key_arg if key_arg is not None else int(round((alpha_arg / math.pi) * 128.0)) & 0xFF
            key = (base_key + p * KEY_INC) % 256 # 刻意錯開 Key
            if key == 0: key = 1 # 避免 0 產生奇異值
            alpha = key * math.pi / 128.0

        all_keys.append(key)

        # 刻意讓每組的輸入資料都不一樣
        in_words = []
        for k in range(32):
            real8 = (k + p * 17) & 0xFF
            imag8 = (0xFF - k - p * 11) & 0xFF
            in_words.append((imag8 << 8) | real8) 

        all_in_words.extend(in_words)

        x_real = np.array([((w & 0xFF) if (w & 0x80) == 0 else (w & 0xFF) - 256) for w in in_words], dtype=np.int64)
        x_imag = np.array([(((w >> 8) & 0xFF) if ((w >> 15) & 1) == 0 else ((w >> 8) & 0xFF) - 256) for w in in_words], dtype=np.int64)

        chirps = generate_chirps(alpha)
        out_r, out_i = frft_1d(x_real, x_imag, chirps)

        # 【重點】只針對第 0 組 (第一組) 產生 Debug Stages
        if p == 0 and dump_stages:
            dbg = frft_1d_debug(x_real, x_imag, chirps)
            # stage_dir = outdir / "stages"
            # stage_dir.mkdir(parents=True, exist_ok=True)
            # stage_keys = [k for k in dbg.keys() if "raw" not in k]
            # for name in stage_keys:
            #     write_stage_hex(stage_dir / f"{name}.hex", dbg[name])
            write_debug_stages_txt(outdir / "debug_stages.txt", in_words, dbg)

        out_words = []
        for i in range(32):
            r_raw = int(out_r[i])
            i_raw = int(out_i[i])
            r16 = r_raw & 0xFFFF
            i16 = i_raw & 0xFFFF
            out_words.append((i16 << 16) | r16)
            all_out_float.append((float(r_raw), float(i_raw)))
            
        all_out_words.extend(out_words)

    # 將 5 組資料一次性寫入同一個檔案
    write_hex_lines(outdir / "input_words_32.hex", all_in_words, 4)
    write_hex_lines(outdir / "output_words_32.hex", all_out_words, 8)
    write_hex_lines(outdir / "key.hex", all_keys, 2)
    
    with open(outdir / "output_float_32.txt", "w") as f:
        for rr, ii in all_out_float:
            f.write(f"{rr:.6f} {ii:.6f}\n")

    print(f"Generated {NUM_PATTERNS} patterns GT at: {outdir}")
    if dump_stages:
        print("Generated debug_stages.txt for Pattern 0")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--gen-gt", action="store_true", help="Generate TB GT files from sim model and exit.")
    ap.add_argument("--alpha", type=float, default=np.pi * 0.7)
    ap.add_argument("--key", type=int, default=None)
    ap.add_argument("--random-alpha", action="store_true")
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--outdir", type=str, default="pattern/gt_2path")
    ap.add_argument("--dump-stages", action="store_true")
    args = ap.parse_args()

    if args.key is not None:
        args.alpha = args.key * np.pi / 128.0

    if args.gen_gt:
        gen_tb_gt_from_sim(
            alpha_arg=args.alpha,
            outdir=args.outdir,
            key_arg=args.key,
            random_alpha=args.random_alpha,
            seed=args.seed,
            dump_stages=args.dump_stages
        )
        raise SystemExit(0)

    if plt is None:
        print("matplotlib is not installed. Use --gen-gt mode or install matplotlib.")
        raise SystemExit(1)

    print("--- Starting 1D FrFT Verification (Complex Input) ---")
    
    alpha_param = args.alpha
    
    t_n = np.arange(32)
    real_part = 100 * np.tanh(2 * np.pi * t_n / 32)
    imag_part = 50 * np.sin(4 * np.pi * t_n / 32)  
    
    x_float = real_part + 1j * imag_part
    x_int_real = np.round(x_float.real).astype(np.int64)
    x_int_imag = np.round(x_float.imag).astype(np.int64)
    
    def theoretical_frft_1d(x, alpha):
        N = len(x)
        t = np.arange(-N//2, N//2) 
        if np.abs(np.sin(alpha)) < 1e-10:
            alpha += 1e-10
        c1 = np.exp(-1j * np.pi * (t**2) * np.tan(alpha / 2))
        A_alpha = np.sqrt((1 - 1j / np.tan(alpha)) / (2 * np.pi))
        c2 = A_alpha * np.exp(1j * np.pi * (t**2) / np.sin(alpha))
        x_c1 = x * c1
        conv_res = np.fft.ifft(np.fft.fft(x_c1) * np.fft.fft(c2))
        return conv_res * c1

    float_result_pos = theoretical_frft_1d(x_float, alpha_param)
    float_result_neg = theoretical_frft_1d(x_float, -alpha_param)
    
    chirps_pos = generate_chirps(alpha_param)
    fnt_r_pos, fnt_i_pos = frft_1d(x_int_real, x_int_imag, chirps_pos)
    
    chirps_neg = generate_chirps(-alpha_param)
    fnt_r_neg, fnt_i_neg = frft_1d(x_int_real, x_int_imag, chirps_neg)
    
    def recover_complex(fnt_r, fnt_i):
        fnt_r_decoded = np.array([v for v in fnt_r], dtype=float)
        fnt_i_decoded = np.array([v for v in fnt_i], dtype=float)
        return fnt_r_decoded + 1j * fnt_i_decoded
    
    fnt_complex_pos = recover_complex(fnt_r_pos, fnt_i_pos)
    fnt_complex_neg = recover_complex(fnt_r_neg, fnt_i_neg)
    
    error_pos = np.abs(float_result_pos - fnt_complex_pos)
    error_neg = np.abs(float_result_neg - fnt_complex_neg)
    
    print("\n--- +alpha ---")
    print(f"MSE: {np.mean(error_pos**2):.6f}")
    print(f"Max Error: {np.max(error_pos):.6f}")
    
    print("\n--- -alpha ---")
    print(f"MSE: {np.mean(error_neg**2):.6f}")
    print(f"Max Error: {np.max(error_neg):.6f}")
    
    fig, axes = plt.subplots(3, 1, figsize=(10, 12))
    
    axes[0].plot(t_n, x_float.real, label="Input Real", marker='o')
    axes[0].plot(t_n, x_float.imag, label="Input Imag", marker='x', linestyle='--')
    axes[0].set_title("Complex Input Signal")
    axes[0].legend()
    axes[0].grid(True, linestyle=':')
    
    axes[1].plot(t_n, float_result_pos.real, label="+α Theoretical", marker='o')
    axes[1].plot(t_n, fnt_complex_pos.real, '--', label="+α FNT", marker='x')
    axes[1].plot(t_n, float_result_neg.real, label="-α Theoretical", marker='s')
    axes[1].plot(t_n, fnt_complex_neg.real, '--', label="-α FNT", marker='d')
    axes[1].set_title("Real Part Comparison")
    axes[1].legend()
    axes[1].grid(True, linestyle=':')
    
    axes[2].plot(t_n, float_result_pos.imag, label="+α Theoretical", marker='o')
    axes[2].plot(t_n, fnt_complex_pos.imag, '--', label="+α FNT", marker='x')
    axes[2].plot(t_n, float_result_neg.imag, label="-α Theoretical", marker='s')
    axes[2].plot(t_n, fnt_complex_neg.imag, '--', label="-α FNT", marker='d')
    axes[2].set_title("Imaginary Part Comparison")
    axes[2].legend()
    axes[2].grid(True, linestyle=':')
    
    plt.tight_layout()
    plt.show()