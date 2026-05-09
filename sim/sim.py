import numpy as np
import scipy.linalg as la
import matplotlib.pyplot as plt

def get_ultimate_V_and_k(N):
    # 1. 構造 S 矩陣
    S = np.zeros((N, N))
    for n in range(N):
        S[n, n] = 2 * np.cos(2 * np.pi * n / N)
        S[n, (n + 1) % N] = 1
        S[n, (n - 1) % N] = 1
        
    # 2. 構造 J 矩陣來打破退化 (保證嚴格的奇偶對稱)
    J = np.zeros((N, N))
    J[0, 0] = 1
    for i in range(1, N):
        J[i, N - i] = 1
        
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
        lam = np.vdot(v, F @ v)
        dft_type = np.argmin([np.abs(lam - val) for val in ideal_eigvals])
        buckets[dft_type].append((z_count, i))
        
    for t in buckets:
        buckets[t].sort(key=lambda x: x[0])
        
    # 3. Pei 階數修正 (最關鍵的一步)
    k_orders = np.arange(N)
    if N % 2 == 0:
        k_orders[-1] = N
        
    sorted_indices = []
    for k in k_orders:
        req_type = k % 4
        if buckets[req_type]:
            sorted_indices.append(buckets[req_type].pop(0)[1])
        else:
            raise ValueError(f"數學機制崩潰：Bucket {req_type} 是空的！")
            
    V = eig_vecs[:, sorted_indices]
    
    for i in range(N):
        idx_max = np.argmax(np.abs(V[:, i]))
        if V[idx_max, i] < 0:
            V[:, i] *= -1
            
    return V, k_orders

def get_ultimate_V(N):
    # 1. 構造 Commuting Matrix S
    S = np.zeros((N, N))
    for n in range(N):
        S[n, n] = 2 * np.cos(2 * np.pi * n / N)
        S[n, (n + 1) % N] = 1
        S[n, (n - 1) % N] = 1
        
    # --- 核心修正：打破特徵值退化 (Degeneracy) ---
    # 建立時間反轉矩陣 J (Time Reversal Matrix)
    J = np.zeros((N, N))
    J[0, 0] = 1
    for i in range(1, N):
        J[i, N - i] = 1
        
    # 將 S 加上一點點 J，分離偶向量與奇向量的特徵值
    S_prime = S + 0.1 * J 
    # ---------------------------------------------
    
    # 現在解出來的 eig_vecs 絕對會是純粹的偶對稱或奇對稱
    eig_vals, eig_vecs = la.eigh(S_prime)
    
    n_idx = np.arange(N)
    F = np.exp(-2j * np.pi * np.outer(n_idx, n_idx) / N) / np.sqrt(N)
    
    buckets = {0: [], 1: [], 2: [], 3: []}
    ideal_eigvals = [1, -1j, -1, 1j]
    
    for i in range(N):
        v = eig_vecs[:, i]
        v_cyclic = np.append(v, v[0])
        z_count = np.where(np.diff(np.sign(v_cyclic + 1e-15)))[0].size
        
        # 因為現在向量超純，lam 算出來會完美貼合 1, -j, -1, j
        lam = np.vdot(v, F @ v)
        dft_type = np.argmin([np.abs(lam - val) for val in ideal_eigvals])
        buckets[dft_type].append((z_count, i))
        
    for t in buckets:
        buckets[t].sort(key=lambda x: x[0])
        
    sorted_indices = []
    for k in range(N):
        req_type = k % 4
        if buckets[req_type]:
            sorted_indices.append(buckets[req_type].pop(0)[1])
        else:
            for t in buckets:
                if buckets[t]:
                    sorted_indices.append(buckets[t].pop(0)[1])
                    break
                    
    V = eig_vecs[:, sorted_indices]
    
    for i in range(N):
        idx_max = np.argmax(np.abs(V[:, i]))
        if V[idx_max, i] < 0:
            V[:, i] *= -1
            
    return V

def get_better_V(N):
    # 1. 構造 Commuting Matrix S
    S = np.zeros((N, N))
    for n in range(N):
        S[n, n] = 2 * np.cos(2 * np.pi * n / N)
        S[n, (n + 1) % N] = 1
        S[n, (n - 1) % N] = 1
    
    eig_vals, eig_vecs = la.eigh(S)
    
    n_idx = np.arange(N)
    F = np.exp(-2j * np.pi * np.outer(n_idx, n_idx) / N) / np.sqrt(N)
    
    # 建立 4 個 Buckets 對應 DFT 特徵值 (1, -1j, -1, 1j)
    buckets = {0: [], 1: [], 2: [], 3: []}
    ideal_eigvals = [1, -1j, -1, 1j]
    
    for i in range(N):
        v = eig_vecs[:, i]
        
        # 修正 1：零交點計算補上 Cyclic 邊界
        v_cyclic = np.append(v, v[0])
        z_count = np.where(np.diff(np.sign(v_cyclic + 1e-15)))[0].size
        
        # 修正 2：正確計算與理想特徵值的距離
        lam = np.vdot(v, F @ v)
        dists = [np.abs(lam - val) for val in ideal_eigvals]
        dft_type = np.argmin(dists) # 找出真正對應的 Eigenspace: 0, 1, 2, 3
        
        buckets[dft_type].append((z_count, i))
        
    # 在各個 Bucket 內依據零交點數量排序
    for t in buckets:
        buckets[t].sort(key=lambda x: x[0])
        
    # 修正 3：按照 k = 0, 1, 2... N-1 提取特徵向量，強制滿足 k mod 4
    sorted_indices = []
    for k in range(N):
        req_type = k % 4
        if buckets[req_type]:
            sorted_indices.append(buckets[req_type].pop(0)[1])
        else:
            # 容錯處理 (避免極端數值退化報錯)
            for t in buckets:
                if buckets[t]:
                    sorted_indices.append(buckets[t].pop(0)[1])
                    break
                    
    V = eig_vecs[:, sorted_indices]
    
    # 符號歸一化 (確保每個 Mode 的主要能量為正)
    for i in range(N):
        idx_max = np.argmax(np.abs(V[:, i]))
        if V[idx_max, i] < 0:
            V[:, i] *= -1
            
    return V

# 注意：Engine 現在要吃 k_orders 來算特徵值
def dfrft_engine(x, alpha, V, k_orders):
    phi = -0.5 * np.pi * k_orders * alpha
    Lambda_alpha = np.exp(1j * phi)
    return V @ (Lambda_alpha * (V.T @ x))

def _dfrft_engine(x, alpha, V):
    N = len(x)
    k = np.arange(N)
    phi = -0.5 * np.pi * k * alpha
    Lambda_alpha = np.exp(1j * phi)
    
    projection = V.T @ x
    rotated = Lambda_alpha * projection
    y = V @ rotated
    return y

# --- 設定模擬 ---
N = 32
#V_auth = get_better_V(N)
#V_auth = get_ultimate_V(N)
V_auth, k_ord = get_ultimate_V_and_k(N)
print(f"For 32 point, k_order:{k_ord}")
print("Real part of V_auth:", V_auth.real)
print("Imag part of V_auth:", V_auth.imag)

# 測試訊號：偏移中心的高斯脈衝
t = np.arange(N)
x_in = np.exp(-(t - N/3)**2 / (N/8)) 

# 計算標準 FFT 
x_fft = np.fft.fft(x_in) / np.sqrt(N)
x_fft_shifted = x_fft

# --- 繪圖比對 (觀察不同 Alpha 的理論平滑過渡) ---
plt.figure(figsize=(16, 8))

# 畫出不同 alpha 角度的變化
alphas_to_test = [0.25, 0.5, 0.75, 1.0]
for idx, a in enumerate(alphas_to_test):
    x_frft = dfrft_engine(x_in, a, V_auth, k_ord)
    
    plt.subplot(2, 4, idx + 1)
    plt.stem(t, x_frft.real, linefmt='C1-', markerfmt='C1o', basefmt=" ")
    plt.title(f"Real part (alpha={a})")
    plt.grid(True, alpha=0.3)
    
    plt.subplot(2, 4, idx + 5)
    plt.stem(t, x_frft.imag, linefmt='C2-', markerfmt='C2o', basefmt=" ")
    plt.title(f"Imag part (alpha={a})")
    plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.show()
plt.close()
# --- 輸出量化指標 ---
x_alpha1 = dfrft_engine(x_in, 1.0, V_auth, k_ord)
print("=== Bug 修正後的誤差指標 ===")
print(f"振幅誤差: {np.linalg.norm(np.abs(x_alpha1) - np.abs(x_fft_shifted)):.2e}")
print(f"實部誤差: {np.linalg.norm(x_alpha1.real - x_fft_shifted.real):.2e}")
print(f"虛部誤差: {np.linalg.norm(x_alpha1.imag - x_fft_shifted.imag):.2e}")


# 假設前面已經定義了 dfrft_engine 和 V_auth
# 測試訊號 (可以是任何奇形怪狀的訊號，這裡加點雜訊讓測試更嚴苛)
np.random.seed(42)
x_test = np.random.randn(N) + 1j * np.random.randn(N)

print("=== DFrFT 數學特性嚴謹驗證 ===")

# 1. 角度加法性測試 (Additivity)
a1, a2 = 0.33, 0.45
res_step1 = dfrft_engine(x_test, a1, V_auth, k_ord)
res_step2 = dfrft_engine(res_step1, a2, V_auth, k_ord)
res_direct = dfrft_engine(x_test, a1 + a2, V_auth, k_ord)
err_add = np.linalg.norm(res_step2 - res_direct)
print(f"[1] 加法性誤差 (0.33 + 0.45 vs 0.78): {err_add:.2e}")

# 2. 可逆性測試 (Reversibility)
a_rev = 0.87
res_fwd = dfrft_engine(x_test, a_rev, V_auth, k_ord)
res_inv = dfrft_engine(res_fwd, -a_rev, V_auth, k_ord)
err_rev = np.linalg.norm(x_test - res_inv)
print(f"[2] 可逆性誤差 (轉 0.87 再轉 -0.87): {err_rev:.2e}")

# 3. 能量守恆測試 (Unitarity)
energy_in = np.sum(np.abs(x_test)**2)
energy_out = np.sum(np.abs(res_fwd)**2)
print(f"[3] 能量守恆誤差 (|Input|^2 vs |Output|^2): {np.abs(energy_in - energy_out):.2e}")

# 4. 特殊角度測試
# alpha = 0 (Identity)
res_a0 = dfrft_engine(x_test, 0.0, V_auth, k_ord)
print(f"[4a] a=0 誤差 (與原訊號比): {np.linalg.norm(x_test - res_a0):.2e}")

# 測試 alpha = 2 (時間反轉)
res_a2 = dfrft_engine(x_test, 2.0, V_auth, k_ord)
x_reversed = np.zeros_like(x_test)
x_reversed[0] = x_test[0]
x_reversed[1:] = x_test[1:][::-1]
print(f"[4b] a=2 誤差 (與時間反轉比): {np.linalg.norm(x_reversed - res_a2):.2e}")

# 測試 alpha = 3 (IFFT)
res_a3 = dfrft_engine(x_test, 3.0, V_auth, k_ord)
x_ifft = np.fft.ifft(x_test) * np.sqrt(N)
print(f"[4c] a=3 誤差 (與 IFFT 比): {np.linalg.norm(x_ifft - res_a3):.2e}")

# ==========================================
# 視覺化：打開找 V 矩陣的黑盒子 (修正 NameError 版)
# ==========================================
def visualize_V_process(N, V):
    # 為了畫圖，我們快速重現一下 S' 矩陣
    S = np.zeros((N, N))
    for n in range(N):
        S[n, n] = 2 * np.cos(2 * np.pi * n / N)
        S[n, (n + 1) % N] = 1
        S[n, (n - 1) % N] = 1
    J = np.zeros((N, N))
    J[0, 0] = 1
    for i in range(1, N): J[i, N - i] = 1
    S_prime = S + 1e-6 * J 

    # === 補上漏掉的 DFT 矩陣 F ===
    n_idx = np.arange(N)
    F = np.exp(-2j * np.pi * np.outer(n_idx, n_idx) / N) / np.sqrt(N)
    # =============================

    plt.figure(figsize=(18, 10))

    # --- Plot 1: S' 矩陣的熱力圖 ---
    plt.subplot(2, 3, 1)
    plt.imshow(S_prime, cmap='viridis')
    plt.colorbar(fraction=0.046, pad=0.04)
    plt.title("1. Commuting Matrix $S'$ Heatmap")
    plt.xlabel("Column Index")
    plt.ylabel("Row Index")

    # --- Plot 2: 最終 V 矩陣的熱力圖 ---
    plt.subplot(2, 3, 4)
    plt.imshow(V, cmap='RdBu', vmin=-0.5, vmax=0.5)
    plt.colorbar(fraction=0.046, pad=0.04)
    plt.title("2. Final Orthogonal Matrix $V$")
    plt.xlabel("k (Order / Mode)")
    plt.ylabel("n (Time Index)")

    # --- Plot 3: 觀察前四階特徵向量 (Hermite-Gaussian Modes) ---
    plt.subplot(2, 3, 2)
    t_idx = np.arange(N)
    # k=0 (純高斯), k=1 (一階導數), k=2 (二階), k=3 (三階)
    colors = ['C0', 'C1', 'C2', 'C3']
    for k in range(4):
        # 為了讓圖好看，稍微把振幅乘上一個常數錯開
        plt.plot(t_idx, V[:, k] + k*0.6, marker='.', color=colors[k], 
                 label=f'k={k}')
    plt.title("3. First 4 Eigenvectors (Discrete Hermite-Gaussian)")
    plt.legend(loc='upper right', fontsize='small')
    plt.grid(True, alpha=0.3)

    # --- Plot 4: 零交點 (Zero-crossing) 視覺化 ---
    plt.subplot(2, 3, 5)
    k_target = 5  # 挑選 k=5 來觀察
    v_target = V[:, k_target]
    plt.plot(t_idx, v_target, 'k-o', label=f'Eigenvector k={k_target}')
    plt.axhline(0, color='gray', linestyle='--')
    
    # 標記零交點
    v_cyclic = np.append(v_target, v_target[0])
    zero_crossings = np.where(np.diff(np.sign(v_cyclic + 1e-15)))[0]
    
    # 畫出紅色的 X 標示交點
    for zc in zero_crossings:
        if zc < N-1: # 畫在兩個點的中間
            x_pos = zc + 0.5
            plt.plot(x_pos, 0, 'rx', markersize=10, markeredgewidth=2)
            
    plt.title(f"4. Zero-crossings for k={k_target} (Count: {len(zero_crossings)})")
    plt.legend()
    plt.grid(True, alpha=0.3)

    # --- Plot 5: 檢查向量的正交性 (Orthogonality Check) ---
    plt.subplot(2, 3, 3)
    # V^T * V 應該要是一個 Identity Matrix (對角線為1，其餘為0)
    identity_check = V.T @ V
    plt.imshow(np.abs(identity_check), cmap='Blues')
    plt.colorbar(fraction=0.046, pad=0.04)
    plt.title(r"5. Orthogonality Check ($V^T V \approx I$)")
    
    # --- Plot 6: 特徵值的相位分佈 ( k_orders 修正效果 ) ---
    plt.subplot(2, 3, 6)
    
    # 計算實際對應的 DFT 特徵值
    actual_eigvals = []
    for i in range(N):
        actual_eigvals.append(np.vdot(V[:, i], F @ V[:, i]))
        
    plt.scatter(range(N), np.real(actual_eigvals), label='Real', marker='o')
    plt.scatter(range(N), np.imag(actual_eigvals), label='Imag', marker='x')
    plt.title("6. DFT Eigenvalue Projections")
    plt.xlabel("k Index")
    plt.legend()
    plt.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.show()

# 呼叫函數畫圖
visualize_V_process(N, V_auth)