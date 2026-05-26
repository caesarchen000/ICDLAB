import numpy as np
import scipy.linalg as la
import matplotlib.pyplot as plt
import math
import sys
import io
import os
from PIL import Image
from tqdm import tqdm
from config import *

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
_IMAGE_PATH = os.path.join(_SCRIPT_DIR, "image_2.png")

if getattr(sys.stdout, "encoding", None) in (None, "ANSI_X3.4-1968", "ascii"):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

error_sweep = True
config_sweep = False

# 輔助函式：模擬 Verilog 截斷與符號
# ==========================================
def _to_signed(val, bits):
    val = int(val) & ((1 << bits) - 1)
    if val >= (1 << (bits - 1)):
        val -= (1 << bits)
    return val

def to_signed(val, bits):
    mask = (1 << bits) - 1
    val = np.asarray(val, dtype=np.int64) & mask
    return np.where(val >= (1 << (bits - 1)), val - (1 << bits), val)

# 👉 替換為 gen_test.py 裡面的「向量旋轉模式」CORDIC
def hw_cordic_rotation(x_in, y_in, phase_in):
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
        # 內部迭代使用 18-bit 防溢位保精度
        x, y, z = to_signed(x_next, CORDIC_INTERMEDIATE), to_signed(y_next, CORDIC_INTERMEDIATE), to_signed(z_next, 16)

    x_out = (x + (1 << (OUTPUT_SHIFT - 1))) >> OUTPUT_SHIFT
    y_out = (y + (1 << (OUTPUT_SHIFT - 1))) >> OUTPUT_SHIFT

    x_out = to_signed(x_out, CORDIC_OUTPUT)
    y_out = to_signed(y_out, CORDIC_OUTPUT)
    return x_out, y_out

# ==========================================
# 矩陣 V 的生成與 CSD (Shift-and-Add) 量化
# ==========================================
def approx_pot_csd(val_int, num_terms):
    """將整數轉換為最多 num_terms 個 2的次方 相加減 (CSD 編碼)"""
    if val_int == 0: return 0, [(0, 0)]
    residual = val_int
    res_val = 0
    ops = []
    for _ in range(num_terms):
        if residual == 0:
            break
        sign = 1 if residual > 0 else -1
        abs_res = abs(residual)
        p = int(round(math.log2(abs_res)))
        ops.append((sign, p))
        value = sign * (1 << p)
        res_val += value
        residual -= value
    
    return res_val, ops

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
    # for K_inv
    return V, k_orders

np.set_printoptions(precision=5, suppress=True, linewidth=200, threshold=np.inf)
V_float, k_orders = get_ultimate_V_and_k(N)
print(f"k_orders:{k_orders}")
np.savetxt("V_float.txt", V_float, fmt="%.10f")

# ==========================================
# 理論與硬體模型
# ==========================================
def theoretical_eigen_dfrft(x_real, x_imag, key):
    angle_param = key * np.pi / 128
    x_c = x_real + 1j * x_imag
    phi = - k_orders * angle_param
    Lambda_alpha = np.exp(1j * phi)
    return V_float @ (Lambda_alpha * (V_float.T @ x_c))

def hw_dfrft_pipeline(x_real, x_imag, key):
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
        phase_val = to_signed(-256 * k_orders[k] * key, 16)
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

def find_unity_gain_v_scale(V_float, V_BITS, MAX_TERMS):
    print("\n啟動「多維度隨機期望值」黃金 V_SCALE 掃描...")
    
    # 1. 準備代表性測資 (Representative Mini-Batch)
    # 選取 16 個均勻分佈的角度，涵蓋 CORDIC 在各象限的表現
    sample_keys = np.linspace(-128, 127, 16, dtype=int)
    num_signals_per_key = 10 
    
    np.random.seed(RANDOM_SEED)
    test_signals_r = np.random.randint(-128, 127, size=(num_signals_per_key, N))
    test_signals_i = np.random.randint(-128, 127, size=(num_signals_per_key, N))

    # 2. 預先計算所有樣本的理論值 (Target with Gain=1.0)
    # 這樣在 loop 內就不用重算理論值
    theory_targets = {}
    for k in sample_keys:
        targets = []
        for i in range(num_signals_per_key):
            targets.append(theoretical_eigen_dfrft(test_signals_r[i], test_signals_i[i], k))
        theory_targets[k] = targets

    # 3. 定義搜索範圍 (使用更精確的步長)
    # 從原本的 1000 點掃描改為兩階段以兼顧效率
    scale_candidates = np.linspace(1.09, 1.15, 200) 
    
    best_scale = 1.10
    min_overall_mse = float('inf')
    best_V_q = None
    
    global V_q
    for test_scale in tqdm(scale_candidates, desc="Searching Scale"):
        # 生成當前 scale 下的量化矩陣
        temp_V_q = np.zeros((N, N), dtype=np.int64)
        for i in range(N):
            for j in range(N):
                val_int = int(round(V_float[i, j] * test_scale * (1 << V_BITS)))
                q_val, _ = approx_pot_csd(val_int, num_terms=MAX_TERMS)
                temp_V_q[i, j] = q_val
        
        V_q = temp_V_q
        
        # 計算在所有樣本下的平均 MSE
        current_total_mse = 0.0
        for k in sample_keys:
            for i in range(num_signals_per_key):
                hw_r, hw_i = hw_dfrft_pipeline(test_signals_r[i], test_signals_i[i], k)
                target = theory_targets[k][i]
                mse = np.mean((target.real - hw_r)**2 + (target.imag - hw_i)**2)
                current_total_mse += mse
        
        avg_mse = current_total_mse / (len(sample_keys) * num_signals_per_key)
        
        if avg_mse < min_overall_mse:
            min_overall_mse = avg_mse
            best_scale = test_scale
            best_V_q = np.copy(temp_V_q)

    # 4. 儲存結果
    V_q = best_V_q
    print(f"\n最佳化完成！")
    print(f"最優補償 Scale: {best_scale:.8f}")
    print(f"樣本平均 MSE: {min_overall_mse:.6f}")
    
    np.savetxt("V_q.txt", V_q, fmt="%6d")
    
    # 同步更新 V_ops.txt
    with open("V_ops.txt", "w") as f:
        for i in range(N):
            for j in range(N):
                val_int = int(round(V_float[i, j] * best_scale * (1 << V_BITS)))
                _, ops = approx_pot_csd(val_int, num_terms=MAX_TERMS)
                f.write(" ".join(f"({s},{p})" for s, p in ops) + "\n")

def find_gain_v_scale(V_float, V_BITS, MAX_TERMS):
    global V_q
    V_q = np.zeros((N, N), dtype=np.int64)
    V_ops = [[None for _ in range(N)] for _ in range(N)]

    for i in range(N):
        for j in range(N):
            val_int = int(round(V_float[i, j] * V_SCALE * (1 << V_BITS)))
            V_q[i, j], ops = approx_pot_csd(val_int, num_terms=MAX_TERMS)
            V_ops[i][j] = ops
    np.savetxt("V_q.txt", V_q, fmt="%6d")

    with open("V_ops.txt", "w") as f:
        for i in range(N):
            for j in range(N):
                ops = V_ops[i][j]
                line = " ".join(f"({s},{p})" for s, p in ops)
                f.write(line + "\n")
    print(f"成功生成 Gain={HW_GAIN} 的 V_q.txt 與 V_ops.txt！SCALE={V_SCALE}")


def load_image_32(path):
    im = Image.open(path).convert("L").resize((N, N), Image.LANCZOS)
    img = np.array(list(im.getdata()), dtype=np.float64).reshape(N, N)
    lo, hi = img.min(), img.max()
    if hi > lo:
        img = (img - lo) / (hi - lo) * 255.0
    return img


def load_rgb_divisible_by_32(path, max_dim=None):
    """
    Load RGB image; resize so H and W are multiples of 32 (LANCZOS).
    Returns (rgb float HxWx3, original_h, original_w).
    """
    im = Image.open(path)
    if im.mode != "RGB":
        im = im.convert("RGB")
    ow, oh = im.size
    w, h = ow, oh
    if max_dim and max(w, h) > max_dim:
        scale = max_dim / float(max(w, h))
        w = max(N, int(round(w * scale)))
        h = max(N, int(round(h * scale)))
    wp = ((w + N - 1) // N) * N
    hp = ((h + N - 1) // N) * N
    if (wp, hp) != (ow, oh):
        im = im.resize((wp, hp), Image.LANCZOS)
    w, h = im.size
    rgb = np.array(list(im.getdata()), dtype=np.float64).reshape(h, w, 3)
    return rgb, oh, ow


def save_rgb(arr_hwc, path):
    u8 = np.clip(np.round(arr_hwc), 0, 255).astype(np.uint8)
    Image.fromarray(u8, mode="RGB").save(path)


def normalize_to_255(arr):
    lo, hi = arr.min(), arr.max()
    if hi > lo:
        return ((arr - lo) / (hi - lo)) * 255.0
    return arr


def save_gray(img, path):
    Image.fromarray(np.clip(np.round(img), 0, 255).astype(np.uint8), mode="L").save(path)


def input_port_limits():
    """Signed range for INPUT_PORT bits (8-bit: -128..127, 9-bit: -256..255)."""
    hi = (1 << (INPUT_PORT - 1)) - 1
    lo = -(1 << (INPUT_PORT - 1))
    return lo, hi


def saturate_to_input(val):
    """宇彥 saturate: clip 11-bit pipeline out to INPUT_PORT signed range (no >>3)."""
    lo, hi = input_port_limits()
    v = int(val)
    if v > hi:
        return hi
    if v < lo:
        return lo
    return v


def saturate_to_input_arr(arr):
    return np.array([saturate_to_input(x) for x in arr], dtype=np.int64)


def print_saturate_clip_stats(raw, label):
    lo_lim, hi_lim = input_port_limits()
    a = np.asarray(raw, dtype=np.int64)
    n = a.size
    hi = int(np.sum(a > hi_lim))
    lo = int(np.sum(a < lo_lim))
    ok = n - hi - lo
    print(
        f"  {label}: {ok}/{n} in-range ({100 * ok / n:.1f}%), "
        f"clip>{hi_lim}: {hi} ({100 * hi / n:.1f}%), "
        f"clip<{lo_lim}: {lo} ({100 * lo / n:.1f}%), "
        f"any: {hi + lo} ({100 * (hi + lo) / n:.1f}%), "
        f"raw [{a.min()}, {a.max()}]  (INPUT_PORT={INPUT_PORT}-bit)"
    )


def quantize_11_to_8_signed(arr):
    """
    Fixed full-range map: signed 11-bit span -> unsigned 0..255 -> signed 8-bit.
      (val - min_11) / (max_11 - min_11) * 255, then -128 for pipeline input.
    Same idea as normalize_to_255 but with fixed limits from OUTPUT_PORT / INPUT_PORT.
    """
    min11 = -(1 << (OUTPUT_PORT - 1))
    max11 = (1 << (OUTPUT_PORT - 1)) - 1
    max_u8 = (1 << INPUT_PORT) - 1
    span11 = max11 - min11
    a = np.clip(np.asarray(arr, dtype=np.int64), min11, max11)
    u8 = np.round((a.astype(np.float64) - min11) * max_u8 / span11)
    u8 = np.clip(u8, 0, max_u8)
    return (u8 - 128).astype(np.int64)


def enc_mag_vis(real, imag):
    return normalize_to_255(np.sqrt(real.astype(float) ** 2 + imag.astype(float) ** 2))


def grey_from_real(real):
    return np.clip(real.astype(np.float64) + 128, 0, 255)


def dfrft_pass_2d(real_in, imag_in, key, along="row", report_clips=False, stage=""):
    """
    Run hw_dfrft on every row or column; saturate 11-bit out to INPUT_PORT bits.
    along: 'row' (axis 0) or 'col' (axis 1)
    """
    out_r = np.zeros((N, N), dtype=np.int64)
    out_i = np.zeros((N, N), dtype=np.int64)
    raw_r, raw_i = [], []
    indices = range(N)
    for idx in indices:
        if along == "row":
            xr, xi = real_in[idx, :].copy(), imag_in[idx, :].copy()
        else:
            xr, xi = real_in[:, idx].copy(), imag_in[:, idx].copy()
        r, ix = hw_dfrft_pipeline(xr, xi, key)
        raw_r.append(r)
        raw_i.append(ix)
        sr, si = saturate_to_input_arr(r), saturate_to_input_arr(ix)
        if along == "row":
            out_r[idx, :], out_i[idx, :] = sr, si
        else:
            out_r[:, idx], out_i[:, idx] = sr, si
    if report_clips:
        label = f"{stage} ({along})"
        print(f"  saturate clips — {label}:")
        print_saturate_clip_stats(np.concatenate(raw_r), "real")
        print_saturate_clip_stats(np.concatenate(raw_i), "imag")
    return out_r, out_i


def process_block_2d(img_block, key_enc=40, key_dec=-40, decrypt_col_first=True, report_clips=False):
    """
    One 32x32 channel (0..255): row enc -> col enc -> col dec -> row dec.
    img_block: (N, N) float grey.
    """
    lo_in, hi_in = input_port_limits()
    real0 = np.clip(np.round(img_block - 128), lo_in, hi_in).astype(np.int64)
    imag0 = np.zeros((N, N), dtype=np.int64)

    enc1_r, enc1_i = dfrft_pass_2d(real0, imag0, key_enc, "row", report_clips=report_clips, stage="enc row")
    enc2_r, enc2_i = dfrft_pass_2d(enc1_r, enc1_i, key_enc, "col", report_clips=report_clips, stage="enc col")

    if decrypt_col_first:
        dec1_r, dec1_i = dfrft_pass_2d(enc2_r, enc2_i, key_dec, "col", report_clips=report_clips, stage="dec col")
        dec2_r, dec2_i = dfrft_pass_2d(dec1_r, dec1_i, key_dec, "row", report_clips=report_clips, stage="dec row")
    else:
        dec1_r, dec1_i = dfrft_pass_2d(enc2_r, enc2_i, key_dec, "row", report_clips=report_clips, stage="dec row")
        dec2_r, dec2_i = dfrft_pass_2d(dec1_r, dec1_i, key_dec, "col", report_clips=report_clips, stage="dec col")

    return {
        "enc1_r": enc1_r,
        "enc1_i": enc1_i,
        "enc2_r": enc2_r,
        "enc2_i": enc2_i,
        "dec_r": dec2_r,
        "dec_grey": grey_from_real(dec2_r),
        "enc1_vis": enc_mag_vis(enc1_r, enc1_i),
        "enc2_vis": enc_mag_vis(enc2_r, enc2_i),
    }


def run_image_row_encrypt_decrypt(key_enc=40, key_dec=-40):
    """1D only: row encrypt then row decrypt (32x32)."""
    img = load_image_32(_IMAGE_PATH)
    lo_in, hi_in = input_port_limits()
    real0 = np.clip(np.round(img - 128), lo_in, hi_in).astype(np.int64)
    imag0 = np.zeros((N, N), dtype=np.int64)
    print(f"\n=== 1D image pipeline (INPUT_PORT={INPUT_PORT}-bit) ===")
    enc_r, enc_i = dfrft_pass_2d(real0, imag0, key_enc, "row", report_clips=True, stage="encrypt")
    dec_r, dec_i = dfrft_pass_2d(enc_r, enc_i, key_dec, "row", report_clips=True, stage="decrypt")
    _save_image_pipeline(img, enc_r, enc_i, dec_r, dec_i, enc_2d_r=None, enc_2d_i=None, tag="1d")


def run_image_2d_encrypt_decrypt(key_enc=40, key_dec=-40, decrypt_col_first=True):
    """Single 32x32 grey block (image.png resized)."""
    img = load_image_32(_IMAGE_PATH)
    lo_in, hi_in = input_port_limits()
    print(f"\n=== 2D block (32x32, INPUT_PORT={INPUT_PORT}-bit, ±{abs(lo_in)}..{hi_in}) ===")
    out = process_block_2d(img, key_enc, key_dec, decrypt_col_first, report_clips=True)
    _save_image_pipeline(
        img, out["enc1_r"], out["enc1_i"], out["dec_r"], out["enc1_i"],
        enc_2d_r=out["enc2_r"], enc_2d_i=out["enc2_i"], tag="2d",
    )


def run_tiled_rgb_encrypt_decrypt(
    path=None, key_enc=40, key_dec=-40, decrypt_col_first=True, max_dim=320
):
    """
    Full RGB image: resize H,W to multiples of 32, then per 32x32 patch per channel
    run the same 2D pipeline as process_block_2d.
    """
    path = path or _IMAGE_PATH
    rgb, orig_h, orig_w = load_rgb_divisible_by_32(path, max_dim=max_dim)
    h, w, _ = rgb.shape
    nbr, nbc = h // N, w // N
    nblocks = nbr * nbc
    lo_in, hi_in = input_port_limits()
    print(f"\n=== Tiled RGB 2D (INPUT_PORT={INPUT_PORT}-bit) ===")
    print(f"  source: {path}  original {orig_w}x{orig_h}  ->  canvas {w}x{h}")
    print(f"  blocks: {nbr}x{nbc} = {nblocks}  x 3 channels = {nblocks * 3} pipeline runs")

    enc1_vis = np.zeros((h, w, 3), dtype=np.float64)
    enc2_vis = np.zeros((h, w, 3), dtype=np.float64)
    dec_rgb = np.zeros((h, w, 3), dtype=np.float64)

    blocks = [(br, bc, ch) for br in range(nbr) for bc in range(nbc) for ch in range(3)]
    for br, bc, ch in tqdm(blocks, desc="32x32 x RGB"):
        rs, cs = br * N, bc * N
        block = rgb[rs : rs + N, cs : cs + N, ch]
        out = process_block_2d(block, key_enc, key_dec, decrypt_col_first, report_clips=False)
        enc1_vis[rs : rs + N, cs : cs + N, ch] = out["enc1_vis"]
        enc2_vis[rs : rs + N, cs : cs + N, ch] = out["enc2_vis"]
        dec_rgb[rs : rs + N, cs : cs + N, ch] = out["dec_grey"]

    rmse = float(np.sqrt(np.mean((rgb - dec_rgb) ** 2)))
    print(f"  full image MSE vs input: {rmse:.2f}")

    save_rgb(rgb, os.path.join(_SCRIPT_DIR, "sim_image_input.png"))
    save_rgb(enc1_vis, os.path.join(_SCRIPT_DIR, "sim_image_encrypted_1d.png"))
    save_rgb(enc2_vis, os.path.join(_SCRIPT_DIR, "sim_image_encrypted_2d.png"))
    save_rgb(dec_rgb, os.path.join(_SCRIPT_DIR, "sim_image_decrypted_2d.png"))

  # Summary figure: downscale for display if large
    preview_scale = min(1.0, 512.0 / max(h, w))
    if preview_scale < 1.0:
        def _down(a):
            im = Image.fromarray(np.clip(np.round(a), 0, 255).astype(np.uint8), mode="RGB")
            nw, nh = int(w * preview_scale), int(h * preview_scale)
            im2 = im.resize((nw, nh), Image.LANCZOS)
            return np.array(list(im2.getdata()), dtype=np.float64).reshape(nh, nw, 3)
        pin, e1, e2, pdec = _down(rgb), _down(enc1_vis), _down(enc2_vis), _down(dec_rgb)
    else:
        pin, e1, e2, pdec = rgb, enc1_vis, enc2_vis, dec_rgb

    fig, ax = plt.subplots(1, 4, figsize=(16, 4))
    for a, (title, data) in zip(
        ax,
        [
            ("Input", pin),
            ("Enc 1D (rows)", e1),
            ("Enc 2D (+cols)", e2),
            (f"Dec  MSE={rmse:.1f}", pdec),
        ],
    ):
        a.imshow(np.clip(data, 0, 255).astype(np.uint8))
        a.set_title(title)
        a.axis("off")
    plt.tight_layout()
    plt.savefig(os.path.join(_SCRIPT_DIR, "sim_image_pipeline.png"), dpi=120, bbox_inches="tight")
    plt.close()
    print("Saved sim_image_*.png (RGB)")


def _save_image_pipeline(img, enc1_r, enc1_i, dec_r, dec_i, enc_2d_r=None, enc_2d_i=None, tag="2d"):
    enc1_vis = enc_mag_vis(enc1_r, enc1_i)
    dec_grey = grey_from_real(dec_r)
    rmse = float(np.sqrt(np.mean((img - dec_grey) ** 2)))
    print(f"  final dec grey unique: {len(np.unique(dec_grey))}, MSE vs input: {rmse:.2f}")

    save_gray(img, os.path.join(_SCRIPT_DIR, "sim_image_input.png"))
    save_gray(enc1_vis, os.path.join(_SCRIPT_DIR, "sim_image_encrypted_1d.png"))
    save_gray(dec_grey, os.path.join(_SCRIPT_DIR, f"sim_image_decrypted_{tag}.png"))

    if enc_2d_r is not None:
        save_gray(enc_mag_vis(enc_2d_r, enc_2d_i), os.path.join(_SCRIPT_DIR, "sim_image_encrypted_2d.png"))

    panels = [("Input", img, "gray"), ("Enc 1D (rows)", enc1_vis, "turbo")]
    if enc_2d_r is not None:
        panels.append(("Enc 2D (+cols)", enc_mag_vis(enc_2d_r, enc_2d_i), "turbo"))
    panels.append((f"Dec ({tag})", dec_grey, "gray"))
    fig, ax = plt.subplots(1, len(panels), figsize=(4 * len(panels), 4))
    if len(panels) == 1:
        ax = [ax]
    for a, (title, data, cmap) in zip(ax, panels):
        a.imshow(data, cmap=cmap, vmin=0, vmax=255)
        a.set_title(title)
        a.axis("off")
    plt.suptitle(f"MSE={rmse:.2f}")
    plt.tight_layout()
    plt.savefig(os.path.join(_SCRIPT_DIR, "sim_image_pipeline.png"), dpi=120, bbox_inches="tight")
    plt.close()
    print("Saved sim_image_*.png")


# ==========================================
# 主程式：測試與繪圖
# ==========================================
if __name__ == "__main__":

    if AUTO_UNITY_GAIN:
        find_unity_gain_v_scale(V_float, V_BITS, MAX_TERMS)
    else:
        find_gain_v_scale(V_float, V_BITS, MAX_TERMS)

    # 如果沒有指定的圖片，就自動生成一張 default 測試圖
    if not os.path.isfile(_IMAGE_PATH):
        print(f"[INFO] Image not found: {_IMAGE_PATH}")
        print("[INFO] Generating default test image...")

        # 生成一張簡單的 RGB 測試圖
        default_size = 128
        x = np.linspace(0, 255, default_size, dtype=np.uint8)
        y = np.linspace(0, 255, default_size, dtype=np.uint8)
        xx, yy = np.meshgrid(x, y)

        default_img = np.zeros((default_size, default_size, 3), dtype=np.uint8)
        default_img[:, :, 0] = xx                  # R: horizontal gradient
        default_img[:, :, 1] = yy                  # G: vertical gradient
        default_img[:, :, 2] = (xx ^ yy)           # B: pattern

        im = Image.fromarray(default_img, mode="RGB")
        im.save(_IMAGE_PATH)

        print(f"[INFO] Default test image saved to: {_IMAGE_PATH}")

    if os.path.isfile(_IMAGE_PATH):
        im = Image.open(_IMAGE_PATH)

        max_dim, force_32 = 320, False
        args = sys.argv[1:]

        i = 0
        while i < len(args):
            if args[i] == "--32":
                force_32 = True
            elif args[i] == "--max" and i + 1 < len(args):
                max_dim = int(args[i + 1])
                i += 1
            i += 1

        if force_32 or (im.size == (N, N) and im.mode in ("L", "1")):
            run_image_2d_encrypt_decrypt()
        else:
            run_tiled_rgb_encrypt_decrypt(_IMAGE_PATH, max_dim=max_dim)

        sys.exit(0)