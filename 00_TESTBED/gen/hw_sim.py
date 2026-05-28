import numpy as np
import scipy.linalg as la
import matplotlib.pyplot as plt
import math
from tqdm import tqdm

error_sweep = True
config_sweep = False

# ==========================================
# 硬體系統常數與 Bit-width 設定
# ==========================================
N = 32
V_BITS = 14       # 矩陣 V 的小數點位數 (Q14)
S1_SHIFT = 10     # Stage 1 算完後的右移量
S2_SHIFT = 10     # Stage 2 (CORDIC 旋轉) 算完後的右移量
# S3_SHIFT = 17     # Stage 3 算完後的最終右移量
S3_SHIFT = 14

# Shift-and-Add 限制
MAX_TERMS = 3     # 👉 硬體限制：每個常數最多由幾個 2 的次方相加減組成 (決定 Adder 數量)

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

def hw_cordic_rotation(x_in, y_in, phase_in):
    """完美模擬硬體 Rotation Mode CORDIC 的定點數行為"""
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
        # 內部寬度對齊 RTL 的 18-bit
        x, y, z = to_signed(x_next, 18), to_signed(y_next, 18), to_signed(z_next, 16)

    # 輸出截斷 (OUTPUT_SHIFT = 5)
    x_out = (x + (1 << (OUTPUT_SHIFT - 1))) >> OUTPUT_SHIFT
    y_out = (y + (1 << (OUTPUT_SHIFT - 1))) >> OUTPUT_SHIFT
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
        # 找出最接近的 2 的次方
        p = int(round(math.log2(abs_res)))
        # hardware operation record
        ops.append((sign, p))   # sign * 2^p
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
    return V, k_orders

# 生成並量化 (Shift-and-add 逼近)
np.set_printoptions(
    precision=5,   # 小數位數
    suppress=True, # 不用科學記號
    linewidth=200,  # 一行不要亂換行
    threshold=np.inf
)
V_float, k_orders = get_ultimate_V_and_k(N)
#print(V_float)
print(f"k_orders:{k_orders}")
np.savetxt(
    "V_float.txt",
    V_float,
    fmt="%.10f"
)

V_q = np.zeros((N, N), dtype=np.int64)
V_ops = [[None for _ in range(N)] for _ in range(N)]

for i in range(N):
    for j in range(N):
        val_int = int(round(V_float[i, j] * (1 << V_BITS)))
        # 在這裡做 CSD 近似，MAX_TERMS=2 代表這在硬體裡最多只要 1 個加法器
        V_q[i, j], ops = approx_pot_csd(val_int, num_terms=MAX_TERMS)
        V_ops[i][j] = ops
#print(V_q)
np.savetxt(
    "V_q.txt",
    V_q,
    fmt="%6d"
)

with open("V_ops.txt", "w") as f:
    for i in range(N):
        for j in range(N):
            ops = V_ops[i][j]
            line = " ".join(f"({s},{p})" for s, p in ops)
            f.write(line + "\n")

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
    # [Stage 1: V^T * x] 
    y1_r_full, y1_i_full = np.zeros(N, dtype=np.int64), np.zeros(N, dtype=np.int64)
    for k in range(N):
        for n in range(N):
            y1_r_full[k] += V_q[n, k] * x_real[n]
            y1_i_full[k] += V_q[n, k] * x_imag[n]
            
    y1_r_q = (y1_r_full + (1 << (S1_SHIFT - 1))) >> S1_SHIFT
    y1_i_q = (y1_i_full + (1 << (S1_SHIFT - 1))) >> S1_SHIFT

    # [Stage 2: CORDIC Rotation]
    y2_r_q, y2_i_q = np.zeros(N, dtype=np.int64), np.zeros(N, dtype=np.int64)
    for k in range(N):
        # 處理 N=32 時最後一個通道的特殊映射 (與 CHIP.v 邏輯一致)
        k_val = 32 if k == 31 else k
        phase_val = to_signed(-256 * k_val * key, 16)
        y2_r_q[k], y2_i_q[k] = hw_cordic_rotation(y1_r_q[k], y1_i_q[k], phase_val)

    # [Stage 3: V * y2]
    y3_r_full, y3_i_full = np.zeros(N, dtype=np.int64), np.zeros(N, dtype=np.int64)
    for n in range(N):
        for k in range(N):
            y3_r_full[n] += V_q[n, k] * y2_r_q[k]
            y3_i_full[n] += V_q[n, k] * y2_i_q[k]

    out_r = (y3_r_full + (1 << (S3_SHIFT - 1))) >> S3_SHIFT
    out_i = (y3_i_full + (1 << (S3_SHIFT - 1))) >> S3_SHIFT
    return out_r, out_i

# def hw_dfrft_pipeline(x_real, x_imag, key):
    # [Stage 1: V^T * x] 
    y1_r_full, y1_i_full = np.zeros(N, dtype=np.int64), np.zeros(N, dtype=np.int64)
    for k in range(N):
        for n in range(N):
            # 注意：Python 寫乘法，但因為 V_q 已經是 CSD 格式，
            # 這在 RTL 裡對應的就是純粹的 `x_real[n] << p1 +/- x_real[n] << p2`
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
# 主程式：測試與繪圖
# ==========================================
if __name__ == "__main__":
    t_n = np.arange(N) # 0, 1, 2, ..., N-1

    # ==========================================
    # 1. 畫出單一 Case (例如 Key = 64, alpha = 0.5)
    # ==========================================
    test_key = 64
    print(f"\n--- Running Single Case Visualization (Key={test_key}) ---")
    
    # 產生一個混和實虛部的有趣訊號
    #x_test_float = 100 * np.exp(-(t_n - 16)**2 / 16) + 1j * 50 * np.sin(4 * np.pi * t_n / N)
    x_test_float = 100 * np.exp(-(t_n - N/3)**2 / (N/8)) + 1j * 50 * np.sin(4 * np.pi * t_n / N)
    #x_test_float = 100 * np.sin((t_n / 2)*np.pi)
    x_test_r = np.clip(np.round(x_test_float.real), -128, 127).astype(np.int64)
    x_test_i = np.clip(np.round(x_test_float.imag), -128, 127).astype(np.int64)
    
    # 理論與硬體結果
    res_float = theoretical_eigen_dfrft(x_test_r, x_test_i, test_key)
    hw_out_r, hw_out_i = hw_dfrft_pipeline(x_test_r, x_test_i, test_key)

    fig1, axes1 = plt.subplots(2, 1, figsize=(12, 8))
    # Input Plot
    axes1[0].plot(t_n, x_test_r, 'ko-', label="Input Real")
    axes1[0].plot(t_n, x_test_i, 'kx--', label="Input Imag")
    axes1[0].set_title(f"Input Signal (8-bit quantized)")
    axes1[0].grid(True, linestyle=':'); axes1[0].legend()
    
    # Output Plot
    axes1[1].plot(t_n, res_float.real, 'ro-', alpha=0.5, label="Theory Real", linewidth=3)
    axes1[1].plot(t_n, hw_out_r, 'rx--', label="HW Real")
    axes1[1].plot(t_n, res_float.imag, 'bo-', alpha=0.5, label="Theory Imag", linewidth=3)
    axes1[1].plot(t_n, hw_out_i, 'bx--', label="HW Imag")
    axes1[1].set_title(f"Output Signal Comparison (Key = {test_key})")
    axes1[1].grid(True, linestyle=':'); axes1[1].legend()
    plt.tight_layout()
    plt.savefig('single_case_comparison.png')
    plt.show()

    if config_sweep:
        import seaborn as sns
        import pandas as pd
        
        # ==========================================
        # 2. 全域 Grid Search & Heatmap 掃描
        # ==========================================
        NUM_SETS = 10                  # 多組測資平均
        keys_array = list(range(-128, 128, 4)) # Step=4 加速掃描
        
        # 要掃描的參數網格 (Grid)
        v_bits_list = [10, 12, 14, 16, 18]
        cordic_stages_list = [8, 9, 10, 11, 12]
        
        results_list = []

        print(f"\n--- Starting Grid Search (Averaging over {NUM_SETS} random sets) ---")
        
        for v_b in v_bits_list:
            for stg in cordic_stages_list:
                print(f"Testing V_BITS={v_b}, CORDIC_STAGES={stg}...")
                
                # 1. 動態更新硬體參數 (在 __main__ 區塊直接賦值即可覆蓋全域變數)
                V_BITS = v_b
                STAGES = stg
                
                # 維持總 Shift 量等於 V_BITS 所帶來的倍率成長
                shift_offset = v_b - 14 
                S1_SHIFT = 10 + shift_offset
                S3_SHIFT = 17 + shift_offset
                
                # 重新計算 CORDIC 常數
                K_INV = get_k_inv(STAGES)
                ATAN_TABLE = ATAN_TABLE_FULL[:STAGES]
                
                # 重新生成量化的 V 矩陣 (CSD)
                V_q = np.zeros((N, N), dtype=np.int64)
                for i in range(N):
                    for j in range(N):
                        val_int = int(round(V_float[i, j] * (1 << V_BITS)))
                        V_q[i, j], _ = approx_pot_csd(val_int, num_terms=MAX_TERMS)
                
                # 2. 進行多組測資的 Error Sweep
                grid_nmse_list = []
                grid_mse_list = []
                grid_worst_mse = 0.0
                
                # 固定 Seed 確保不同架構評估的公平性
                np.random.seed(42) 
                
                for _ in range(NUM_SETS):
                    x_int_real = np.random.randint(-128, 128, size=N)
                    x_int_imag = np.random.randint(-128, 128, size=N)
                    
                    for k in keys_array:
                        res_float = theoretical_eigen_dfrft(x_int_real, x_int_imag, k)
                        hw_r, hw_i = hw_dfrft_pipeline(x_int_real, x_int_imag, k)
                        
                        mse_r = np.mean((res_float.real - hw_r)**2)
                        mse_i = np.mean((res_float.imag - hw_i)**2)
                        total_mse = mse_r + mse_i
                        sig_pwr = np.mean(np.abs(res_float)**2)
                        
                        grid_mse_list.append(total_mse)
                        grid_nmse_list.append(total_mse / (sig_pwr + 1e-12))
                        
                        if total_mse > grid_worst_mse:
                            grid_worst_mse = total_mse
                
                # 記錄該組設定的平均結果
                results_list.append({
                    'V_BITS': v_b,
                    'CORDIC_STAGES': stg,
                    'Avg_NMSE': np.mean(grid_nmse_list),
                    'Avg_MSE': np.mean(grid_mse_list),
                    'Worst_MSE': grid_worst_mse
                })

        # ==========================================
        # 3. 繪製 Heatmap
        # ==========================================
        df_results = pd.DataFrame(results_list)
        
        # 建立 Pivot Tables
        pivot_nmse = df_results.pivot(index="V_BITS", columns="CORDIC_STAGES", values="Avg_NMSE")
        pivot_avg_mse = df_results.pivot(index="V_BITS", columns="CORDIC_STAGES", values="Avg_MSE")
        pivot_worst = df_results.pivot(index="V_BITS", columns="CORDIC_STAGES", values="Worst_MSE")

        # 畫 3 張圖：NMSE, Avg MSE, Worst MSE
        fig3, axes3 = plt.subplots(1, 3, figsize=(20, 6))
        
        # Plot 1: Average NMSE (取 log10 增加顏色對比)
        sns.heatmap(np.log10(pivot_nmse), annot=pivot_nmse, fmt=".2e", 
                    cmap="YlGnBu_r", ax=axes3[0], cbar_kws={'label': 'log10(NMSE)'})
        axes3[0].set_title(f"Average NMSE (10 sets, MAX_TERMS={MAX_TERMS})")
        axes3[0].invert_yaxis()
        
        # Plot 2: Average MSE (取 log10 增加顏色對比)
        sns.heatmap(np.log10(pivot_avg_mse), annot=pivot_avg_mse, fmt=".1f", 
                    cmap="Oranges", ax=axes3[1], cbar_kws={'label': 'log10(Avg MSE)'})
        axes3[1].set_title(f"Average MSE across all angles")
        axes3[1].invert_yaxis()

        # Plot 3: Worst Case MSE (線性尺度)
        sns.heatmap(pivot_worst, annot=True, fmt=".0f", 
                    cmap="Reds", ax=axes3[2], cbar_kws={'label': 'Worst MSE'})
        axes3[2].set_title(f"Worst Case MSE across all angles")
        axes3[2].invert_yaxis()
        
        plt.tight_layout()
        plt.savefig('heatmap_grid_search_3panels.png', dpi=300)
        print("\nHeatmap saved as 'heatmap_grid_search_3panels.png'.")
        plt.show()


    if error_sweep:
        # ==========================================
        # 2. 全域 MSE 掃描
        # ==========================================
        NUM_SAMPLES = 10
        keys_array = list(range(-128, 128))
        mse_real, mse_imag, nmse_list = [], [], []

        print("\n--- Sweeping Errors over all Keys with RANDOM 8-bit inputs ---")
        for k in tqdm(keys_array):
            total_mse_r, total_mse_i, total_sig_pwr = 0.0, 0.0, 0.0
            
            for _ in range(NUM_SAMPLES):
                x_int_real = np.random.randint(-128, 128, size=N)
                x_int_imag = np.random.randint(-128, 128, size=N)
                
                res_float = theoretical_eigen_dfrft(x_int_real, x_int_imag, k)
                hw_r, hw_i = hw_dfrft_pipeline(x_int_real, x_int_imag, k)
                
                total_mse_r += np.mean((res_float.real - hw_r)**2)
                total_mse_i += np.mean((res_float.imag - hw_i)**2)
                total_sig_pwr += np.mean(np.abs(res_float)**2)

            mse_real.append(total_mse_r / NUM_SAMPLES)
            mse_imag.append(total_mse_i / NUM_SAMPLES)
            nmse_list.append((total_mse_r + total_mse_i) / (total_sig_pwr + 1e-12))

        print("\n=== Hardware Bit-True Performance Summary ===")
        print(f"Overall MSE        : {np.mean(mse_real) + np.mean(mse_imag):.6e}")
        print(f"Overall NMSE       : {np.mean(nmse_list):.6e}")
        print(f"Worst-case MSE     : {np.max(np.array(mse_real)+np.array(mse_imag)):.6e}")

        # 畫線性 MSE 掃描圖
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
