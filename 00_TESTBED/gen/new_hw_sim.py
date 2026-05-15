import numpy as np
import scipy.linalg as la
import matplotlib.pyplot as plt
import math
from tqdm import tqdm
from config import *

error_sweep = True
config_sweep = False

# ==========================================
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

# ==========================================
# 主程式：測試與繪圖
# ==========================================
if __name__ == "__main__":
    t_n = np.arange(N)

    # ==========================================
    # 1. 畫出單一 Case (例如 Key = 64)
    # ==========================================
    test_key = 64
    print(f"\n--- Running Single Case Visualization (Key={test_key}) ---")
    
    x_test_float = 100 * np.exp(-(t_n - N/3)**2 / (N/8)) + 1j * 50 * np.sin(4 * np.pi * t_n / N)
    x_test_r = np.clip(np.round(x_test_float.real), -128, 127).astype(np.int64)
    x_test_i = np.clip(np.round(x_test_float.imag), -128, 127).astype(np.int64)
    
    # 👉 理論結果必須乘上硬體管線的 HW_GAIN 才能互相對齊比較
    res_float = theoretical_eigen_dfrft(x_test_r, x_test_i, test_key) * HW_GAIN
    hw_out_r, hw_out_i = hw_dfrft_pipeline(x_test_r, x_test_i, test_key)

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
    axes1[0].set_title(f"Input Signal (8-bit quantized)")
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
            total_mse_r, total_mse_i, total_sig_pwr = 0.0, 0.0, 0.0
            for _ in range(NUM_SAMPLES):
                x_int_real = np.random.randint(-128, 128, size=N)
                x_int_imag = np.random.randint(-128, 128, size=N)
                #print(x_int_real)
                #print(x_int_imag)

                # 👉 記得乘上 Gain
                res_float = theoretical_eigen_dfrft(x_int_real, x_int_imag, k) * HW_GAIN
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

    if config_sweep:
        import seaborn as sns
        import pandas as pd

        NUM_SETS = 5
        keys_array = list(range(-128, 128, 4))

        # sweep parameters
        cordic_stages_list = [8, 9, 10, 11, 12]
        max_terms_list = [1, 2, 3, 4]

        results_list = []

        print(f"\n--- Starting Architecture Sweep ---")
        print(f"Fixed V_BITS={V_BITS}, Fixed shifts")
        print(f"Sweeping CORDIC_STAGES and MAX_TERMS")

        np.random.seed(67)

        for stg in cordic_stages_list:
            for max_terms in max_terms_list:

                print(f"\nTesting STAGES={stg}, MAX_TERMS={max_terms}")

                # --------------------------------------
                # update global parameters
                # --------------------------------------
                STAGES = stg
                ATAN_TABLE = ATAN_TABLE_FULL[:STAGES]

                # regenerate V_q using current MAX_TERMS
                V_q = np.zeros((N, N), dtype=np.int64)

                for i in range(N):
                    for j in range(N):
                        val_int = int(round(V_float[i, j] * (1 << V_BITS)))
                        V_q[i, j], _ = approx_pot_csd(
                            val_int,
                            num_terms=max_terms
                        )

                # --------------------------------------
                # error accumulation
                # --------------------------------------
                mse_list = []
                nmse_list = []
                worst_mse = 0.0

                for _ in range(NUM_SETS):

                    x_int_real = np.random.randint(-128, 128, size=N)
                    x_int_imag = np.random.randint(-128, 128, size=N)

                    for k in keys_array:

                        # theory
                        res_float = (
                            theoretical_eigen_dfrft(
                                x_int_real,
                                x_int_imag,
                                k
                            ) * HW_GAIN
                        )

                        # hardware
                        hw_r, hw_i = hw_dfrft_pipeline(
                            x_int_real,
                            x_int_imag,
                            k
                        )

                        # error
                        total_mse = (
                            np.mean((res_float.real - hw_r) ** 2)
                            +
                            np.mean((res_float.imag - hw_i) ** 2)
                        )

                        sig_pwr = np.mean(np.abs(res_float) ** 2)

                        nmse = total_mse / (sig_pwr + 1e-12)

                        mse_list.append(total_mse)
                        nmse_list.append(nmse)

                        if total_mse > worst_mse:
                            worst_mse = total_mse

                # save result
                results_list.append({
                    "CORDIC_STAGES": stg,
                    "MAX_TERMS": max_terms,
                    "AVG_MSE": np.mean(mse_list),
                    "AVG_NMSE": np.mean(nmse_list),
                    "WORST_MSE": worst_mse
                })

        # ==========================================
        # DataFrame
        # ==========================================
        df_results = pd.DataFrame(results_list)

        pivot_nmse = df_results.pivot(
            index="MAX_TERMS",
            columns="CORDIC_STAGES",
            values="AVG_NMSE"
        )

        pivot_mse = df_results.pivot(
            index="MAX_TERMS",
            columns="CORDIC_STAGES",
            values="AVG_MSE"
        )

        pivot_worst = df_results.pivot(
            index="MAX_TERMS",
            columns="CORDIC_STAGES",
            values="WORST_MSE"
        )

        # ==========================================
        # Plot
        # ==========================================
        fig, axes = plt.subplots(1, 3, figsize=(20, 6))

        sns.heatmap(
            np.log10(pivot_nmse),
            annot=pivot_nmse,
            fmt=".2e",
            cmap="YlGnBu_r",
            ax=axes[0],
            cbar_kws={'label': 'log10(NMSE)'}
        )

        axes[0].set_title("Average NMSE")
        axes[0].invert_yaxis()

        sns.heatmap(
            np.log10(pivot_mse),
            annot=pivot_mse,
            fmt=".1f",
            cmap="Oranges",
            ax=axes[1],
            cbar_kws={'label': 'log10(MSE)'}
        )

        axes[1].set_title("Average MSE")
        axes[1].invert_yaxis()

        sns.heatmap(
            pivot_worst,
            annot=True,
            fmt=".0f",
            cmap="Reds",
            ax=axes[2],
            cbar_kws={'label': 'Worst MSE'}
        )

        axes[2].set_title("Worst-case MSE")
        axes[2].invert_yaxis()

        plt.tight_layout()

        plt.savefig(
            f'heatmap_architecture_sweep_VBITS{V_BITS}.png',
            dpi=300
        )

        plt.show()

        # ==========================================
        # print best config
        # ==========================================
        best_idx = df_results["AVG_NMSE"].idxmin()

        print("\n===== BEST CONFIG =====")
        print(df_results.loc[best_idx])