import numpy as np
import matplotlib.pyplot as plt
from PIL import Image
import argparse

# --- System Constants ---
M = 2**32 + 1
J = 2**16
N = 32
# 將量化尺度稍微調降，以確保在軟體模擬中，經過多次乘法後的數值
# 較不容易產生破壞性的截斷誤差，從而提高解密還原的視覺品質。
Q_SCALE = 128
Q_SCALE_1 = 128.0
Q_SCALE_2 = 32.0  

def mod_add(a, b): return (a + b) % M
def mod_sub(a, b): return (a - b) % M
def mod_mul(a, b): return (int(a) * int(b)) % M


def _wrap_alpha(alpha):
    return (float(alpha) + np.pi) % (2 * np.pi) - np.pi


def _safe_alpha_terms(alpha, eps=1e-6):
    """
    Return numerically safe (alpha, sin(alpha), tan(alpha/2), cot(alpha)).
    Only guards singular points; does not change the core algorithm.
    """
    a = _wrap_alpha(alpha)

    s = np.sin(a)
    if abs(s) < eps:
        s = eps if s >= 0 else -eps

    t2 = np.tan(a / 2.0)
    if abs(t2) < eps:
        t2 = eps if t2 >= 0 else -eps

    t = np.tan(a)
    if abs(t) < eps:
        cot_a = 1.0 / (eps if t >= 0 else -eps)
    elif abs(t) > (1.0 / eps):
        # Near +/-pi/2, cot(alpha) -> 0
        cot_a = 0.0
    else:
        cot_a = 1.0 / t

    return a, s, t2, cot_a


def _snap_special_alpha(alpha, eps=1e-9):
    """
    Snap alpha to mathematically singular / limit orders and label:
    - alpha == 0  -> identity (FrFT order 0)
    - alpha == odd*pi -> reversal (FrFT order 2, discrete indexing convention)

    Note: alpha = +/-pi/2 is NOT singular in the chirp kernel; use normal path.

    Important: do NOT use a wide "near-zero" band in key units. That creates a
    discontinuity between keys that take the identity shortcut vs keys that use
    the full chirp pipeline (shows up as spikes a few keys away from 0).
    """
    a = _wrap_alpha(alpha)
    if abs(a) < eps:
        return 0.0, "id"
    # Wrapped domain is (-pi, pi], so only pi (not 2pi) is reachable here.
    if abs(abs(a) - np.pi) < eps:
        return np.pi, "rev"
    return a, None


def _apply_special_operator(x, special):
    if special == "id":
        return np.array(x, dtype=np.complex128, copy=True)
    if special == "rev":
        return np.array(x[::-1], dtype=np.complex128, copy=True)
    return None

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

    # Always build chirps from the actual wrapped angle. Singular handling
    # lives in _safe_alpha_terms (cot/csc/tan half), so we do not replace alpha
    # with a synthetic value here — that would desync FNT chirps from the
    # float reference just outside the identity snap band.
    alpha_s = _wrap_alpha(alpha)

    _, sin_a, tan_half_a, cot_a = _safe_alpha_terms(alpha_s)

    # Chirp-form FrFT (matches written definition):
    # T_r[n]=T_t[n]=exp(-j * n^2/2 * tan(alpha/2))
    # T_s[n]=exp(+j * n^2/2 * csc(alpha))
    # A_alpha = sqrt((1 - j cot(alpha)) / (2*pi))
    c1 = np.exp(-1j * (t**2) / 2.0 * tan_half_a)

    A_alpha = np.sqrt((1 - 1j * cot_a) / (2 * np.pi))
    #A_alpha = 1
    c2 = A_alpha * np.exp(1j * (t**2) / 2.0 / sin_a)
    
    c1_r, c1_i = np.round(c1.real * Q_SCALE_1), np.round(c1.imag * Q_SCALE_1)
    c2_r, c2_i = np.round(c2.real * Q_SCALE_2), np.round(c2.imag * Q_SCALE_2)
    # 為了畫面整潔，若在迴圈內掃描，可將列印資訊註解掉
    # print("Chirp2 real before SCC")
    # print(c2_r)
    # print("Chirp2 imag before SCC")
    # print(c2_i)
    
    c1_p1, c1_p2 = complex_to_scc(c1_r, c1_i)
    c2_p1, c2_p2 = complex_to_scc(c2_r, c2_i)

    C2_p1 = fnt_32(c2_p1)
    C2_p2 = fnt_32(c2_p2)

    return c1_p1, c1_p2, C2_p1, C2_p2

# --- 2. 有限體數值解碼 ---
def decode_mod(val, M):
    """將有限體 M 上的正數映射回實際的正負浮點數"""
    return val if val < M/2 else val - M

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
    pos_2_15 = 2**15
    inv_32 = M - 2**27 

    Q3 = int((Q_SCALE_1**2) * Q_SCALE_2)
    Q3_inv = pow(Q3, -1, M) 
    # print("Q3_inv:", Q3_inv)

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
    
    alpha_s, special = _snap_special_alpha(alpha)
    y_sp = _apply_special_operator(x, special)
    if y_sp is not None:
        return y_sp

    _, sin_a, tan_half_a, cot_a = _safe_alpha_terms(_wrap_alpha(alpha))

    c1 = np.exp(-1j * (t**2) / 2.0 * tan_half_a)
    A_alpha = np.sqrt((1 - 1j * cot_a) / (2 * np.pi))
    c2 = A_alpha * np.exp(1j * (t**2) / 2.0 / sin_a)

    x_c1 = x * c1
    conv_res = np.fft.ifft(np.fft.fft(x_c1) * np.fft.fft(c2))
    
    return conv_res * c1


def fnt_or_special_1d(x_real, x_imag, alpha):
    """
    For singular/limit alpha orders (0, pi), bypass chirp path.
    For all other alpha (including +/-pi/2), use the normal chirp pipeline.
    """
    _, special = _snap_special_alpha(alpha)
    x_c = x_real.astype(np.float64) + 1j * x_imag.astype(np.float64)
    y_sp = _apply_special_operator(x_c, special)
    if y_sp is not None:
        return y_sp.real, y_sp.imag

    chirps = generate_chirps(_wrap_alpha(alpha))
    r_fnt, i_fnt = frft_1d(x_real, x_imag, chirps)
    return r_fnt, i_fnt


# --- 執行比對測試 ---
if __name__ == "__main__":
    # 解析命令列參數
    parser = argparse.ArgumentParser(description="FrFT FNT Verification")
    parser.add_argument(
        '-key',
        type=int,
        default=1,
        help="Alpha key: alpha = key * pi / 128. Typical sweep range [-128, 127].",
    )
    args = parser.parse_args()

    print(f"--- Starting 1D FrFT Verification (Complex Input) for Key: {args.key} ---")
    
    # 將 key 轉換為對應的角度
    alpha_param = args.key * np.pi / 128
    
    # 建立測試訊號 (加入實部與虛部)
    t_n = np.arange(32)
    real_part = 100 * np.tanh(2 * np.pi * t_n / 32)
    imag_part = 100 * np.sin(4 * np.pi * t_n / 32)  # 加入一個正弦波作為虛部
    
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
    fnt_r_pos, fnt_i_pos = fnt_or_special_1d(x_int_real, x_int_imag, alpha_param)
    
    # =========================
    # [3] FNT FrFT (-alpha)
    # =========================
    fnt_r_neg, fnt_i_neg = fnt_or_special_1d(x_int_real, x_int_imag, -alpha_param)
    
    # =========================
    # [4] decode function
    # =========================
    def recover_complex(fnt_r, fnt_i):
        fnt_r_decoded = np.array([v for v in fnt_r], dtype=int)
        fnt_i_decoded = np.array([v for v in fnt_i], dtype=int)
        return fnt_r_decoded + 1j * fnt_i_decoded

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
    # [6] visualization (Single Key)
    # =========================
    fig, axes = plt.subplots(3, 1, figsize=(10, 12))
    
    # Input signal
    axes[0].plot(t_n, x_float.real, label="Input Real", marker='o')
    axes[0].plot(t_n, x_float.imag, label="Input Imag", marker='x', linestyle='--')
    axes[0].set_title(f"Complex Input Signal (Key = {args.key})")
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
    plt.savefig('test.png')
    
    # =========================
    # [7] 新增：進行全部 Key 範圍的誤差掃描
    # =========================
    print("\n--- Sweeping Errors over all Keys ([-128, 127]) ---")
    keys_array = list(range(-128, 128))
    mse_real = []
    mse_imag = []

    for k in keys_array:
        a_val = k * np.pi / 128
        
        # Theoretical float result
        res_float = theoretical_frft_1d(x_float, a_val)
        
        # FNT result
        r_fnt, i_fnt = fnt_or_special_1d(x_int_real, x_int_imag, a_val)
        comp_fnt = recover_complex(r_fnt, i_fnt)
        
        # 計算 MSE 誤差
        e_real = np.mean((res_float.real - comp_fnt.real)**2)
        e_imag = np.mean((res_float.imag - comp_fnt.imag)**2)
        
        mse_real.append(e_real)
        mse_imag.append(e_imag)
        
    # =========================
    # [8] 繪製誤差折線圖
    # =========================
    fig2, ax2 = plt.subplots(figsize=(10, 5))
    ax2.plot(keys_array, mse_real, label="MSE Real Part", color='blue')
    ax2.plot(keys_array, mse_imag, label="MSE Imaginary Part", color='red', linestyle='--')
    ax2.set_title("FrFT Error (MSE) vs. Angle Key ($\\alpha = \\text{key} \\times \\pi/128$)")
    ax2.set_xlabel("Key")
    ax2.set_ylabel("Mean Squared Error (MSE)")
    ax2.grid(True, linestyle=':')
    ax2.legend()
    
    plt.tight_layout()
    plt.savefig('error_sweep.png')
    
    # 一併顯示兩張圖表
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