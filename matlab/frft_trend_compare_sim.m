% =========================================================================
% 16-point DFrFT Hardware-to-Ideal Trend Compare Simulator
% Specification: N=32, Modulus=65537, Input=8b+8b, Chirp=3b, j=256
% Objective: Compare Hardware Bit-Accurate output with scaled Ideal Float output.
% =========================================================================
function frft_trend_compare_sim()
    clc; clear; close all;

    N = 32;
    Fq = 65537;
    
    % 設定加密金鑰角度 (可以嘗試修改此角度看看趨勢的變化)
    alpha = 0.5 * pi/2; 
    
    disp(['=== DFrFT 趨勢比對仿真 (N=', num2str(N), ', alpha=', num2str(alpha), ') ===']);
    disp('--- 系統初始化與測資產生 ---');
    
    % 1. 產生一個有意義的 8-bit signed 測試信號 (-128 ~ 127)
    n_idx = 0:(N-1);
    X_re_in = round(50 * cos(2*pi*n_idx/N) + 20); 
    X_im_in = round(30 * sin(2*pi*n_idx/N) - 10);
    
    X_float_in = X_re_in + 1j * X_im_in;
    
    % 2. 產生真實的 Chirp 訊號 (包含浮點數與 3-bit 硬體量化)
    [C1_hw, C2_hw, C3_hw, C1_fl, C2_fl, C3_fl] = generate_real_chirps(N, alpha);

    % =====================================================================
    % 階段 0-4: 硬體仿真資料路徑 (Bit-Accurate)
    % =====================================================================
    disp('--- 執行硬體仿真 ---');
    
    % 0. 輸入介面 (Fermat Mapping + Concatenation)
    X_hw_conc = zeros(1, N);
    for i = 1:N
        re_f = to_fermat(X_re_in(i));
        im_f = to_fermat(X_im_in(i));
        X_hw_conc(i) = mod_fold(re_f + bitshift(im_f, 8)); 
    end

    % 1. Chirp I 預處理
    SRAM = zeros(1, N);
    for i = 1:N
        SRAM(i) = fermat_mult(X_hw_conc(i), C1_hw(i));
    end

    % 2. 正向 FNT
    SRAM = bit_reverse_array(SRAM); 
    SRAM = run_fnt_stages(SRAM, 'forward');

    % 3. Chirp II 費馬域卷積
    for i = 1:N
        SRAM(i) = fermat_mult(SRAM(i), C2_hw(i));
    end

    % 4. 反向 IFNT (包含 N_inv)
    SRAM = bit_reverse_array(SRAM);
    SRAM = run_fnt_stages(SRAM, 'inverse');
    
    N_inv = 63489; % 32^(-1) mod 65537
    for i = 1:N
        SRAM(i) = fermat_mult(SRAM(i), N_inv);
    end

    % 5. Chirp III 後處理與位元切割 (Output Interface)
    X_hw_out_re = zeros(1, N);
    X_hw_out_im = zeros(1, N);
    for i = 1:N
        Y_conc = fermat_mult(SRAM(i), C3_hw(i));
        
        re_uint = bitand(Y_conc, 255); 
        im_uint = bitshift(Y_conc, -8);
        
        X_hw_out_re(i) = from_2s_comp(re_uint);
        X_hw_out_im(i) = from_2s_comp(im_uint);
    end

    % =====================================================================
    % 理想浮點數解答 (Golden Model)
    % =====================================================================
    disp('--- 計算理想浮點解答 (Golden Model) ---');
    
    % 使用 MATLAB 內建的 fft / ifft 執行完美的連續數學卷積
    H1 = X_float_in .* C1_fl;
    % MATLAB ifft 會除以 N，所以要乘回來保持等比例
    H2 = ifft( fft(H1) .* fft(C2_fl) ) * N; 
    Y_ideal_fl = H2 .* C3_fl;
    
    X_ideal_re = real(Y_ideal_fl);
    X_ideal_im = imag(Y_ideal_fl);
    
    % =====================================================================
    % 趨勢比對與正規化 (Trend Comparison & Scaling)
    % =====================================================================
    disp('--- 趨勢比對與正規化繪圖 ---');
    
    % 注意：由於硬體是量化後的結果，振幅絕對值與浮點結果不同。
    % 為了比較趨勢，我們需要將理想解答正規化。
    % 我們使用標準差（振幅波動範圍）來縮放理想解答。
    
    % 計算實部與虛部的標準差 (Standard Deviation)
    std_hw_re = std(X_hw_out_re);
    std_hw_im = std(X_hw_out_im);
    std_ideal_re = std(X_ideal_re);
    std_ideal_im = std(X_ideal_im);
    
    % 計算縮放係數 (以標準差比值為準，並加上硬體均值)
    scale_re = std_hw_re / std_ideal_re;
    scale_im = std_hw_im / std_ideal_im;
    mean_hw_re = mean(X_hw_out_re);
    mean_hw_im = mean(X_hw_out_im);
    
    % 生成正規化後的理想解答 (Scaled Ideal)
    X_ideal_re_scaled = mean_hw_re + (X_ideal_re - mean(X_ideal_re)) * scale_re;
    X_ideal_im_scaled = mean_hw_im + (X_ideal_im - mean(X_ideal_im)) * scale_im;

    % =====================================================================
    % 繪圖對比 (Trend Plot)
    % =====================================================================
    figure('Name', 'DFrFT Trend Compare: Hardware vs Ideal', 'Position', [100, 100, 1000, 600]);
    n_axis = 0:(N-1);
    
    % 實部對比
    subplot(2,1,1);
    plot(n_axis, X_hw_out_re, 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b'); hold on;
    plot(n_axis, X_ideal_re_scaled, 'r--x', 'LineWidth', 2);
    title(['DFrFT 實部趨勢對比 (alpha=', num2str(alpha), ')']);
    ylabel('振幅');
    legend('硬體仿真 (8-bit signed)', '理想解答 (Scaled Float)');
    grid on;
    
    % 虛部對比
    subplot(2,1,2);
    plot(n_axis, X_hw_out_im, 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b'); hold on;
    plot(n_axis, X_ideal_im_scaled, 'r--x', 'LineWidth', 2);
    title('DFrFT 虛部趨勢對比');
    xlabel('時間索引 (n)'); ylabel('振幅');
    legend('硬體仿真 (8-bit signed)', '理想解答 (Scaled Float)');
    grid on;
    
    disp(['硬體實部標準差: ', num2str(std_hw_re), ', 理想實部標準差: ', num2str(std_ideal_re)]);
    disp('** 觀察: 硬體與理想解答雖然不會完全重合，但震盪趨勢會是非常吻合的。 **');
    disp('--- 趨勢比對完成 ---');
end
%{
% =========================================================================
% 16-point DFrFT Hardware Bit-Accurate Simulator (with Stage Dump & Float Verify)
% Specification: N=32, Modulus=65537, Input=8b+8b, Chirp=3b, j=256
% =========================================================================
function frft_hardware_sim()
    clc; clear;

    N = 32;
    Fq = 65537;
    alpha = 0.5 * pi/2; % 設定分數階數 p = 0.5 (旋轉角度)
    
    disp('======================================================');
    disp('--- 系統初始化與真實測資產生 ---');
    % 1. 產生 8-bit 2's complement 測試資料 (這裡用一個簡單的弦波加上直流)
    n_idx = 0:(N-1);
    X_re_in = round(50 * cos(2*pi*n_idx/N) + 20); 
    X_im_in = round(30 * sin(2*pi*n_idx/N) - 10);
    
    disp('[Stage 0-A] Input Real:'); disp(X_re_in);
    disp('[Stage 0-B] Input Imag:'); disp(X_im_in);
    
    % 2. 產生真正的 FrFT Chirp 訊號 (包含浮點數與 3-bit 硬體量化)
    [Chirp1_hw, Chirp2_hw, Chirp3_hw, C1_fl, C2_fl, C3_fl] = generate_real_chirps(N, alpha);

    % =====================================================================
    % 階段 0: 輸入介面 (2's complement -> Fermat Mapping -> j=2^8 拼接)
    % =====================================================================
    X_hw = zeros(1, N);
    for i = 1:N
        re_f = to_fermat(X_re_in(i));
        im_f = to_fermat(X_im_in(i));
        X_hw(i) = mod_fold(re_f + bitshift(im_f, 8)); 
    end
    disp('------------------------------------------------------');
    disp('[Stage 0-C] Hardware Input (16-bit Concatenated in Fermat):'); 
    disp(X_hw);

    % =====================================================================
    % 階段 1: Chirp I 預處理 (17-bit * 17-bit)
    % =====================================================================
    SRAM = zeros(1, N);
    for i = 1:N
        SRAM(i) = fermat_mult(X_hw(i), Chirp1_hw(i));
    end
    disp('------------------------------------------------------');
    disp('[Stage 1] After Chirp I Multiplication (SRAM Dump):'); 
    disp(SRAM);
    SRAM_stg1 = SRAM;

    % =====================================================================
    % 階段 2: 正向 FNT
    % =====================================================================
    SRAM = bit_reverse_array(SRAM); 
    SRAM = run_fnt_stages(SRAM, 'forward');
    disp('------------------------------------------------------');
    disp('[Stage 2] After Forward FNT (Fermat Domain Spectrum):'); 
    disp(SRAM);
    SRAM_stg2 = SRAM;

    % =====================================================================
    % 階段 3: Chirp II 費馬域卷積
    % =====================================================================
    for i = 1:N
        SRAM(i) = fermat_mult(SRAM(i), Chirp2_hw(i));
    end
    disp('------------------------------------------------------');
    disp('[Stage 3] After Chirp II Convolution (SRAM Dump):'); 
    disp(SRAM);
    SRAM_stg3 = SRAM;

    % =====================================================================
    % 階段 4: 反向 IFNT 
    % =====================================================================
    SRAM = bit_reverse_array(SRAM);
    SRAM = run_fnt_stages(SRAM, 'inverse');
    
    N_inv = 63489; % 32^(-1) mod 65537
    for i = 1:N
        SRAM(i) = fermat_mult(SRAM(i), N_inv);
    end
    disp('------------------------------------------------------');
    disp('[Stage 4] After Inverse FNT (Back to Time Domain):'); 
    disp(SRAM);
    SRAM_stg4 = SRAM;

    % =====================================================================
    % 階段 5: Chirp III 後處理與位元切割
    % =====================================================================
    Out_re = zeros(1, N);
    Out_im = zeros(1, N);
    for i = 1:N
        Y_final = fermat_mult(SRAM(i), Chirp3_hw(i));
        
        re_uint = bitand(Y_final, 255); 
        im_uint = bitshift(Y_final, -8);
        
        Out_re(i) = from_2s_comp(re_uint);
        Out_im(i) = from_2s_comp(im_uint);
    end
    disp('------------------------------------------------------');
    disp('[Stage 5-A] Final Hardware Output Real:'); disp(Out_re);
    disp('[Stage 5-B] Final Hardware Output Imag:'); disp(Out_im);

    % =====================================================================
    % 真實浮點數 FFT 對照組 (Floating-Point Golden Model)
    % =====================================================================
    disp('======================================================');
    disp('--- 啟動浮點數等效模型 (FFT-based) 進行比對 ---');
    X_float = X_re_in + 1j * X_im_in;
    
    % 使用 MATLAB 內建的 fft / ifft 執行完美的連續數學卷積
    H1 = X_float .* C1_fl;
    H2 = ifft( fft(H1) .* fft(C2_fl) ) * N; % MATLAB ifft 會除以 N，所以要乘回來保持等比例
    Y_float = H2 .* C3_fl;
    
    disp('Ideal Float Output Real (Scaled to compare shape):'); 
    disp(round(real(Y_float) / max(abs(real(Y_float))) * max(abs(Out_re)))); % 正規化以便觀察波形趨勢
    
    disp('** 注意: 硬體結果與浮點結果不會完全一致，因為 3-bit 量化會產生嚴重的失真，但整體波形的震盪趨勢會是吻合的。 **');

    % =====================================================================
    % 繪圖視覺化 (專為 .mlx Live Script 優化的內嵌排版)
    % =====================================================================
    % 開啟一個乾淨的圖形物件，讓 Live Editor 自動接管顯示位置
    figure; 
    
    % 使用現代的 tiledlayout 排版 (支援 R2019b 以上版本)，自動適應 mlx 寬度
    t = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(t, 'DFrFT 16-point Hardware Data Path', 'FontWeight', 'bold', 'FontSize', 14);

    n_axis = 0:(N-1);

    % [Stage 0] 原始輸入 (8-bit 2's comp)
    nexttile;
    stem(n_axis, X_re_in, 'b', 'filled'); hold on;
    stem(n_axis, X_im_in, 'r', 'filled');
    title('Stage 0: Input (8-bit Real & Imag)');
    legend('Real', 'Imag', 'Location', 'best'); grid on; ylim([-130 130]);

    % [Stage 1] Chirp I 乘法後 (17-bit Fermat)
    nexttile;
    stem(n_axis, SRAM_stg1, 'b', 'filled');
    title('Stage 1: After Chirp I (17-bit)');
    grid on; ylim([0 65537]);

    % [Stage 2] FNT 轉換後 (費馬域頻譜)
    nexttile;
    stem(n_axis, SRAM_stg2, 'm', 'filled');
    title('Stage 2: Forward FNT (Fermat Domain)');
    grid on; ylim([0 65537]);

    % [Stage 3] Chirp II 卷積後 (費馬域頻譜)
    nexttile;
    stem(n_axis, SRAM_stg3, 'g', 'filled');
    title('Stage 3: Chirp II Conv (Fermat Domain)');
    grid on; ylim([0 65537]);

    % [Stage 4] IFNT 轉換後 (退回時域的 17-bit)
    nexttile;
    stem(n_axis, SRAM_stg4, 'c', 'filled');
    title('Stage 4: Inverse FNT (17-bit)');
    grid on; ylim([0 65537]);

    % [Stage 5] 解碼輸出 (8-bit 2's comp)
    nexttile;
    stem(n_axis, Out_re, 'b', 'filled'); hold on;
    stem(n_axis, Out_im, 'r', 'filled');
    title('Stage 5: Output (8-bit Real & Imag)');
    legend('Real', 'Imag', 'Location', 'best'); grid on; ylim([-130 130]);
end
%}

% =========================================================================
% 硬體模組函式 (維持不變，僅列出新增或修改的函式)
% =========================================================================

% --- [新增] 產生真實的 FrFT Chirp 訊號 ---
function [C1_hw, C2_hw, C3_hw, C1_fl, C2_fl, C3_fl] = generate_real_chirps(N, alpha)
    t = 0:(N-1);
    
    % 1. 計算理想浮點數 Chirp
    C1_fl = exp(-1j * pi * t.^2 * tan(alpha/2) / N);
    C2_fl = exp( 1j * pi * t.^2 * csc(alpha) / N);
    C3_fl = exp(-1j * pi * t.^2 * tan(alpha/2) / N);
    
    % 2. 模擬硬體 3-bit 量化 (範圍 -4 ~ 3)
    quantize = @(x) min(max(round(real(x) * 3), -4), 3) + 1j * min(max(round(imag(x) * 3), -4), 3);
    
    C1_q = quantize(C1_fl);
    C2_q = quantize(C2_fl);
    C3_q = quantize(C3_fl);
    
    % 3. 將 Chirp 2 轉換至費馬域 (FNT) - 在 Python 離線階段完成
    % 這裡用 MATLAB 模擬 Chirp 2 的 FNT 預算
    C2_hw = zeros(1, N);
    C2_mapped = zeros(1, N);
    for i=1:N
        re_f = to_fermat(real(C2_q(i)));
        im_f = to_fermat(imag(C2_q(i)));
        C2_mapped(i) = mod_fold(re_f + bitshift(im_f, 8));
    end
    % 對 C2_mapped 跑 FNT
    C2_hw = run_fnt_stages(bit_reverse_array(C2_mapped), 'forward');
    
    % 4. 轉換 Chirp 1 和 Chirp 3 到硬體格式
    C1_hw = zeros(1, N);
    C3_hw = zeros(1, N);
    for i=1:N
        C1_hw(i) = mod_fold(to_fermat(real(C1_q(i))) + bitshift(to_fermat(imag(C1_q(i))), 8));
        C3_hw(i) = mod_fold(to_fermat(real(C3_q(i))) + bitshift(to_fermat(imag(C3_q(i))), 8));
    end
end

% --- 其餘函式照舊 (run_fnt_stages, mod_fold, fermat_mult, etc.) ---
function SRAM = run_fnt_stages(SRAM, mode)
    N = numel(SRAM);
    stages = log2(N);
    for stg = 0:(stages-1)
        stride = 2^stg;
        chunk = 2^(stg+1);
        for i = 0:(N-1)
            if mod(i, chunk) < stride
                idxA = i + 1;           
                idxB = i + stride + 1;
                A = SRAM(idxA);
                B = SRAM(idxB);
                k = mod(i, chunk) * (N / chunk);
                if strcmp(mode, 'forward')
                    shift_s = mod(2 * k, 32); 
                else
                    shift_s = mod(2 * (N - k), 2*N); 
                end
                B_shifted = fermat_shift(B, shift_s);
                SRAM(idxA) = mod_fold(A + B_shifted);
                temp_diff = A - B_shifted;
                if temp_diff < 0, temp_diff = temp_diff + 65537; end
                SRAM(idxB) = temp_diff;
            end
        end
    end
end

function out = mod_fold(P)
    P_low = bitand(P, 65535);
    P_high = bitshift(P, -16);
    result = P_low - P_high;
    if result < 0, result = result + 65537;
    elseif result >= 65537, result = result - 65537; end
    out = result;
end

function out = fermat_mult(A, B)
    P = A * B;
    out = mod_fold(P);
end

function out_array = bit_reverse_array(in_array)
    N = numel(in_array);
    bits = log2(N);
    out_array = zeros(1, N);
    for i = 0:(N-1)
        bin_str = dec2bin(i, bits);
        rev_str = reverse(bin_str);
        rev_idx = bin2dec(rev_str);
        out_array(rev_idx + 1) = in_array(i + 1);
    end
end

function f_val = to_fermat(val)
    if val < 0, f_val = 65537 + val; else, f_val = val; end
end

function val = from_2s_comp(uint_val)
    if uint_val > 127, val = uint_val - 256; else, val = uint_val; end
end

function out = fermat_shift(B, s)
    s = mod(s, 32);
    if s >= 16, shift_amt = s - 16; negate = true;
    else, shift_amt = s; negate = false; end
    P = bitshift(B, shift_amt);
    res = mod_fold(P);
    if negate
        if res == 0, out = 0; else, out = 65537 - res; end
    else, out = res; end
end