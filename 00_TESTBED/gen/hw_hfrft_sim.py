import numpy as np
import scipy.linalg as la
import matplotlib.pyplot as plt
import math
from tqdm import tqdm
from config import *

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

# 👉 升級為 Unified CORDIC (嚴格限制在 11 個 Stage 內)
def hw_unified_cordic(x_in, y_in, phase_in, mode=0):
    x_in = to_signed(x_in, CORDIC_INPUT)
    y_in = to_signed(y_in, CORDIC_INPUT)
    phase_in = to_signed(phase_in, 16)
    
    if mode == 0:
        # 圓周模式：大角度預旋轉
        if phase_in > 16384 or phase_in < -16384:
            x, y = -x_in, -y_in
            z = to_signed(phase_in - 32768 if phase_in > 0 else phase_in + 32768, 16)
        else:
            x, y = x_in, y_in
            z = phase_in
        i = 0
    else:
        # 雙曲模式：不需預旋轉，且雙曲的 i 從 1 開始
        x, y = x_in, y_in
        z = phase_in
        i = 1

    # 嚴格執行 11 次 Pipeline 疊代
    for stage in range(STAGES): # STAGES = 11
        sign = (z < 0)
        x_shift, y_shift = x >> i, y >> i
        
        if mode == 0:
            # 圓周旋轉 (原本的邏輯)
            if not sign:
                x_next, y_next, z_next = x - y_shift, y + x_shift, z - ATAN_TABLE[i]
            else:
                x_next, y_next, z_next = x + y_shift, y - x_shift, z + ATAN_TABLE[i]
            i += 1  # 圓周模式穩定遞增：0, 1, 2, ..., 10
        else:
            # 雙曲推擠
            if not sign:
                x_next = x + y_shift
                y_next = y + x_shift
                z_next = z - ATANH_TABLE[i]
            else:
                x_next = x - y_shift
                y_next = y - x_shift
                z_next = z + ATANH_TABLE[i]
            
            # 🔥 雙曲收斂的核心：在第 4 步（也就是 stage == 4）時，i 不加 1
            # 這樣下一個 stage (stage==5) 就會重複使用 i=4 進行移位
            if i == 4 and stage == 3: 
                pass # 凍結 i，下一輪繼續用 i=4
            else:
                i += 1 # 雙曲序列：1, 2, 3, 4, 4, 5, 6, 7, 8, 9, 10

        # 內部迭代
        x = to_signed(x_next, CORDIC_INTERMEDIATE)
        y = to_signed(y_next, CORDIC_INTERMEDIATE)
        z = to_signed(z_next, 16)

    if mode == 0:
        x_out = (x + (1 << (OUTPUT_SHIFT_1 - 1))) >> OUTPUT_SHIFT_1
        y_out = (y + (1 << (OUTPUT_SHIFT_1 - 1))) >> OUTPUT_SHIFT_1
    else :
        x_out = (x + (1 << (OUTPUT_SHIFT_2 - 1))) >> OUTPUT_SHIFT_2
        y_out = (y + (1 << (OUTPUT_SHIFT_2 - 1))) >> OUTPUT_SHIFT_2
    return to_signed(x_out, CORDIC_OUTPUT), to_signed(y_out, CORDIC_OUTPUT)

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
    # key 現在可以是複數：key = key_real + 1j * key_imag
    key_real = np.real(key)
    key_imag = np.imag(key)
    
    angle_param_r = key_real * np.pi / 128
    angle_param_i = key_imag * np.pi / 128
    
    x_c = x_real + 1j * x_imag
    
    # 實部對應原本的相位旋轉，虛部對應振幅的雙曲縮放
    phi_r = - k_orders * angle_param_r
    phi_i = - k_orders * angle_param_i
    
    # 核心數學變更：Lambda 變成同時包含旋轉與雙曲實數指數
    Lambda_alpha = np.exp(1j * phi_r) * np.exp(phi_i) 
    
    return V_float @ (Lambda_alpha * (V_float.T @ x_c))

def hw_dfrft_pipeline(x_real, x_imag, key):
    key_real = int(np.real(key))
    key_imag = int(np.imag(key))

    # input storage
    x_real = to_signed(x_real, INPUT_PORT)
    x_imag = to_signed(x_imag, INPUT_PORT)

    # ==========================================
    # [Stage 1: V^T * x] (維持不變)
    # ==========================================
    x_real = to_signed(x_real, MAC_INPUT)
    x_imag = to_signed(x_imag, MAC_INPUT)
    y1_r_full, y1_i_full = np.zeros(N, dtype=np.int64), np.zeros(N, dtype=np.int64)
    for k in range(N):
        for n in range(N):
            y1_r_full[k] += to_signed(V_q[n, k] * x_real[n], MAC_INTERMEDIATE)
            y1_i_full[k] += to_signed(V_q[n, k] * x_imag[n], MAC_INTERMEDIATE)
            
    y1_r_q = to_signed((y1_r_full + (1 << (S1_SHIFT - 1))) >> S1_SHIFT, MAC_OUTPUT)
    y1_i_q = to_signed((y1_i_full + (1 << (S1_SHIFT - 1))) >> S1_SHIFT, MAC_OUTPUT)

    # ==========================================
    # [Stage 2: Two-Pass / TDM CORDIC Pipeline]
    # ==========================================
    y2_r_q = np.zeros(N, dtype=np.int64)
    y2_i_q = np.zeros(N, dtype=np.int64)
    
    for k in range(N):
        # --- Pass 1: 處理實部 key_real (圓周旋轉) ---
        phase_real = to_signed(-256 * k_orders[k] * key_real, 16)
        rot_r, rot_i = hw_unified_cordic(y1_r_q[k], y1_i_q[k], phase_real, mode=0)
        
        # --- Pass 2: 處理虛部 key_imag (雙曲縮放) ---
        # 數學原理：x_hyper = x * exp(phi), y_hyper = y * exp(phi)
        # 用雙曲 CORDIC 計算 exp(phi) 時，需將輸入設為 (rot_r, rot_r) 與 (rot_i, rot_i)
        phase_imag = to_signed(-256 * k_orders[k] * key_imag, 16) # 雙曲角度
        
        # 分時多工 (TDM)：硬體上共用同一個 CORDIC 算兩次
        hyp_r, _ = hw_unified_cordic(rot_r, rot_r, phase_imag, mode=1)
        hyp_i, _ = hw_unified_cordic(rot_i, rot_i, phase_imag, mode=1)
        
        y2_r_q[k] = hyp_r
        y2_i_q[k] = hyp_i

    # ==========================================
    # [Stage 3: V * y2] (維持不變)
    # ==========================================
    y2_r_q = to_signed(y2_r_q, MAC_INPUT)
    y2_i_q = to_signed(y2_i_q, MAC_INPUT)
    y3_r_full, y3_i_full = np.zeros(N, dtype=np.int64), np.zeros(N, dtype=np.int64)
    for n in range(N):
        for k in range(N):
            y3_r_full[n] += to_signed(V_q[n, k] * y2_r_q[k], MAC_INTERMEDIATE)
            y3_i_full[n] += to_signed(V_q[n, k] * y2_i_q[k], MAC_INTERMEDIATE)

    out_r = to_signed((y3_r_full + (1 << (S3_SHIFT - 1))) >> S3_SHIFT, MAC_OUTPUT)
    out_i = to_signed((y3_i_full + (1 << (S3_SHIFT - 1))) >> S3_SHIFT, MAC_OUTPUT)

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


# ==========================================
# 主程式：測試與繪圖
# ==========================================
if __name__ == "__main__":
    
    if AUTO_UNITY_GAIN:
        find_unity_gain_v_scale(V_float, V_BITS, MAX_TERMS)
    else:
        find_gain_v_scale(V_float, V_BITS, MAX_TERMS)
        
    t_n = np.arange(N)

    # ==========================================
    # 1. 畫出單一 Case (例如 Key = 64)
    # ==========================================
    test_key = 64 + 1j * 1/8
    print(f"\n--- Running Single Case Visualization (Key={test_key}) ---")

    print("Input: built-in Gaussian")
    x_test_float = 100 * np.exp(-(t_n - N/3)**2 / (N/8)) + 1j * 50 * np.sin(
        4 * np.pi * t_n / N
    )
    x_test_r = np.clip(np.round(x_test_float.real), -128, 127).astype(np.int64)
    x_test_i = np.clip(np.round(x_test_float.imag), -128, 127).astype(np.int64)
    
    # 👉 理論結果必須乘上硬體管線的 HW_GAIN 才能互相對齊比較
    res_float = theoretical_eigen_dfrft(x_test_r, x_test_i, test_key) * HW_GAIN
    hw_out_r, hw_out_i = hw_dfrft_pipeline(x_test_r, x_test_i, test_key)
    print(hw_out_r)
    print(hw_out_i)
    mse_r = np.mean((res_float.real - hw_out_r)**2)
    mse_i = np.mean((res_float.imag - hw_out_i)**2)
    worst_mse = max(np.max((res_float.real - hw_out_r)**2), np.max(res_float.imag - hw_out_i)**2)
    sig_pwr = np.mean(np.abs(res_float)**2)
    nmse = (mse_r + mse_i) / (sig_pwr + 1e-12)

    print("\n=== Hardware Bit-True Performance Case Study ===")
    print(f"Real MSE   : {mse_r:.6e}")
    print(f"Imag MSE   : {mse_i:.6e}")
    print(f"R+I MSE    : {mse_r+mse_i:.6e}")
    print(f"NMSE       : {nmse:.6e}")
    print(f"Worst MSE  : {worst_mse:.6e}")

    fig1, axes1 = plt.subplots(2, 1, figsize=(12, 8))
    axes1[0].plot(t_n, x_test_r, 'ko-', label="Input Real")
    axes1[0].plot(t_n, x_test_i, 'kx--', label="Input Imag")
    in_title = "Input (8-bit)"
    axes1[0].set_title(in_title)
    axes1[0].grid(True, linestyle=':'); axes1[0].legend()
    
    axes1[1].plot(t_n, res_float.real, 'ro-', alpha=0.5, label="Theory Real (Scaled by Gain)", linewidth=3)
    axes1[1].plot(t_n, hw_out_r, 'rx--', label="HW Real")
    axes1[1].plot(t_n, res_float.imag, 'bo-', alpha=0.5, label="Theory Imag (Scaled by Gain)", linewidth=3)
    axes1[1].plot(t_n, hw_out_i, 'bx--', label="HW Imag")
    axes1[1].set_title(f"Output Signal Comparison (Key = {test_key})")
    axes1[1].grid(True, linestyle=':'); axes1[1].legend()
    plt.tight_layout()
    plt.savefig('single_case_comparison.png')
    plt.show()

    if error_sweep:
        NUM_SAMPLES = 10
        keys_array = list(range(-128, 128))
        #keys_array = [64]
        mse_real, mse_imag, nmse_list = [], [], []

        print("\n--- Sweeping Errors over all Keys with RANDOM 8-bit inputs ---")
        for k in tqdm(keys_array):
            total_mse_r, total_mse_i, total_nmse = 0.0, 0.0, 0.0
            for _ in range(NUM_SAMPLES):
                x_int_real = np.random.randint(-128, 128, size=N)
                x_int_imag = np.random.randint(-128, 128, size=N)
                #print(x_int_real)
                #print(x_int_imag)

                # 👉 記得乘上 Gain
                res_float = theoretical_eigen_dfrft(x_int_real, x_int_imag, k) * HW_GAIN
                hw_r, hw_i = hw_dfrft_pipeline(x_int_real, x_int_imag, k)
                mse_r = np.mean((res_float.real - hw_r)**2)
                mse_i = np.mean((res_float.imag - hw_i)**2)
                total_mse_r += mse_r
                total_mse_i += mse_i
                sig_pwr = np.mean(np.abs(res_float)**2)
                nmse = (mse_r + mse_i) / (sig_pwr + 1e-12)
                #total_sig_pwr += np.mean(np.abs(res_float)**2)
                total_nmse += nmse
            
            mse_real.append(total_mse_r / NUM_SAMPLES)
            mse_imag.append(total_mse_i / NUM_SAMPLES)
            nmse_list.append(total_nmse / NUM_SAMPLES)
            #nmse_list.append((total_mse_r + total_mse_i) / (total_sig_pwr + 1e-12))

        print("\n=== Hardware Bit-True Performance Summary ===")
        print(f"Overall MSE        : {np.mean(mse_real) + np.mean(mse_imag):.6e}")
        print(f"Overall NMSE       : {np.mean(nmse_list):.6e}")
        print(f"Worst-case MSE     : {np.max(np.array(mse_real)+np.array(mse_imag)):.6e}")

        fig2, ax2 = plt.subplots(figsize=(10, 5))
        ax2.plot(keys_array, mse_real, label="MSE Real Part", color='blue')
        ax2.plot(keys_array, mse_imag, label="MSE Imag Part", color='red', linestyle='--')
        ax2.set_title(f"Eigen-DFrFT Error vs. Angle Key (Linear Scale, MAX_TERMS={MAX_TERMS})")
        ax2.set_xlabel("Key")
        ax2.set_ylabel("Mean Squared Error (MSE)")
        ax2.grid(True, linestyle=':')
        ax2.legend()
        plt.tight_layout()
        plt.savefig('error_sweep_eigen_hw.png')
        plt.show()