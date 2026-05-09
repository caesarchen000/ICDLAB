import numpy as np
import scipy.linalg as la
import matplotlib.pyplot as plt

# ==========================================
# 1. 矩陣特徵分解法 (Pei-type DFrFT - 你寫的硬體導向版)
# ==========================================
def get_better_V(N):
    S = np.zeros((N, N))
    for n in range(N):
        S[n, n] = 2 * np.cos(2 * np.pi * n / N)
        S[n, (n + 1) % N] = 1
        S[n, (n - 1) % N] = 1
    eig_vals, eig_vecs = la.eigh(S)
    n_idx = np.arange(N)
    F = np.exp(-2j * np.pi * np.outer(n_idx, n_idx) / N) / np.sqrt(N)
    
    buckets = {0: [], 1: [], 2: [], 3: []}
    ideal_eigvals = [1, -1j, -1, 1j]
    for i in range(N):
        v = eig_vecs[:, i]
        v_cyclic = np.append(v, v[0])
        z_count = np.where(np.diff(np.sign(v_cyclic + 1e-15)))[0].size
        lam = np.vdot(v, F @ v)
        dft_type = np.argmin([np.abs(lam - val) for val in ideal_eigvals])
        buckets[dft_type].append((z_count, i))
        
    for t in buckets: buckets[t].sort(key=lambda x: x[0])
        
    sorted_indices = []
    for k in range(N):
        req_type = k % 4
        if buckets[req_type]: sorted_indices.append(buckets[req_type].pop(0)[1])
        else:
            for t in buckets:
                if buckets[t]:
                    sorted_indices.append(buckets[t].pop(0)[1])
                    break
    V = eig_vecs[:, sorted_indices]
    for i in range(N):
        if V[np.argmax(np.abs(V[:, i])), i] < 0: V[:, i] *= -1
    return V

def dfrft_engine(x, alpha, V):
    N = len(x)
    k = np.arange(N)
    phi = -0.5 * np.pi * k * alpha
    return V @ (np.exp(1j * phi) * (V.T @ x))

# ==========================================
# 2. 理論逼近法 (Chirp Convolution - 基於你提供的程式碼)
# ==========================================
def theoretical_chirp_frft(x, alpha):
    N = len(x)
    # 將座標平移至對稱區間，符合連續積分的特性
    t = np.arange(-N//2, N//2)
    phi = alpha * np.pi / 2

    # 處理特殊角度 (避免 tan/sin 算出版零錯誤)
    alpha_mod = alpha % 4
    if np.isclose(alpha_mod, 0): return x
    if np.isclose(alpha_mod, 2): return x[::-1]
    if np.isclose(alpha_mod, 1): return np.fft.fftshift(np.fft.fft(np.fft.ifftshift(x))) / np.sqrt(N)

    csc_a = 1.0 / np.sin(phi)
    cot_a = 1.0 / np.tan(phi)
    tan_half_a = np.tan(phi / 2.0)

    # 離散化修正：指數項內的 t^2 必須除以 N，否則高頻 Chirp 會嚴重 Aliasing
    c1 = np.exp(-1j * np.pi * (t**2) / N * tan_half_a) 
    c2 = np.exp(1j * np.pi * (t**2) / N * csc_a)
    
    A_alpha = np.sqrt((1 - 1j * cot_a) / N)

    x_c1 = x * c1
    # 執行 Circular Convolution
    conv_res = np.fft.ifft(np.fft.fft(x_c1) * np.fft.fft(c2))
    
    # 輸出前把訊號 Shift 回 0~N-1 的 index 以利對比
    return np.fft.ifftshift(conv_res * c1 * A_alpha)

# ==========================================
# 3. 測試與視覺化比較
# ==========================================
N = 32
alpha_val = 1.0
V_auth = get_better_V(N)

t_idx = np.arange(N)
# 輸入一個乾淨的高斯波
x_in = np.exp(-(t_idx - N//2)**2 / (N/4))

# 分別用兩種方法計算 alpha = 0.5
y_matrix = dfrft_engine(x_in, alpha_val, V_auth)
y_chirp = theoretical_chirp_frft(x_in, alpha_val)

# --- 畫圖 ---
plt.figure(figsize=(16, 6))

plt.subplot(1, 3, 1)
plt.plot(t_idx, x_in, 'ko-', label='Input Signal')
plt.title("Original Signal")
plt.legend()
plt.grid(True, alpha=0.4)

plt.subplot(1, 3, 2)
plt.plot(t_idx, np.abs(y_matrix), 'r-o', label='Matrix DFrFT (Pei)')
plt.plot(t_idx, np.abs(y_chirp), 'b--x', label='Chirp Conv (Theoretical)')
plt.title(f"Amplitude Comparison (alpha={alpha_val})")
plt.legend()
plt.grid(True, alpha=0.4)

plt.subplot(1, 3, 3)
plt.plot(t_idx, np.angle(y_matrix), 'r-o', label='Matrix DFrFT (Pei)')
plt.plot(t_idx, np.angle(y_chirp), 'b--x', label='Chirp Conv (Theoretical)')
plt.title(f"Phase Comparison (alpha={alpha_val})")
plt.legend()
plt.grid(True, alpha=0.4)

plt.tight_layout()
plt.show()