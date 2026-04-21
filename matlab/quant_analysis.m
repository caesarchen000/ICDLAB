% =========================================================================
% 【終極版】 DFrFT 硬體量化分析與 65537 費馬環最佳化腳本
% 包含：A_alpha 振幅補償、C1/C3 資源折疊 (ROM Reuse)、非對稱量化分配
% =========================================================================
clc; clear; close all;

N = 16;
alpha = 0.5 * pi/2; % 設定分數階數

disp('=== 啟動 DFrFT 系統級量化分析 ===');

% 1. 產生 8-bit 輸入訊號 (-128 ~ 127)
n_idx = 0:(N-1);
X_re_in = round(50 * cos(2*pi*n_idx/N) + 20); 
X_im_in = round(30 * sin(2*pi*n_idx/N) - 10);
X_in = X_re_in + 1j * X_im_in;

% 2. 產生理想浮點數 Chirp
t = 0:(N-1);
C1_fl = exp(-0.5j * pi/2 * t.^2 * tan(alpha/2));
C2_fl = exp(-0.5j * pi/2 * t.^2 * csc(alpha));
C3_fl = exp(-0.5j * pi/2 * t.^2 * tan(alpha/2));

% 3. 計算並整合 A_alpha 補償常數
A_alpha = sqrt((1 - 1j*cot(alpha)) / (2*pi));

% 4. 產生完美的 Golden Model (浮點數理想解答，必須包含 A_alpha)
Y_ideal = (ifft( fft(X_in .* C1_fl) .* fft(C2_fl) ) * N) .* C3_fl * A_alpha;

% -------------------------------------------------------------------------
% 🌟 硬體優化：將 A_alpha 吸收進 C2 裡面，解放 C1 與 C3 共用 ROM！
% -------------------------------------------------------------------------
C2_fl_absorbed = C2_fl * A_alpha; 
C13_fl = C1_fl; % C1 和 C3 共用同一個數學陣列

% 定義通用量化函數 (模擬硬體整數查表再除以倍率)
quantize = @(C, S) round(C * S) / S;


% =========================================================================
% [第一部分] 理想環條件下：掃描量化位元數 (Bit-width) vs 誤差
% =========================================================================
bit_range = 3:12; % 掃描 2-bit 到 12-bit
rmse_errors = zeros(size(bit_range)); 
max_errors = zeros(size(bit_range));  

for i = 1:length(bit_range)
    b = bit_range(i);
    scale_factor = 2^(b-1) - 1; % 對稱量化倍率
    
    % 在掃描時，我們對吸收了 A_alpha 的新 Chirp 進行量化
    C13_q = quantize(C13_fl, scale_factor);
    C2_q  = quantize(C2_fl_absorbed, scale_factor);
    
    % 執行量化版 DFrFT (注意頭尾都用 C13_q)
    Y_q = (ifft( fft(X_in .* C13_q) .* fft(C2_q) ) * N) .* C13_q;
    
    error_vector = abs(Y_ideal - Y_q);
    rmse_errors(i) = sqrt(mean(error_vector.^2));
    max_errors(i) = max(error_vector);            
end

% 繪製分析圖表
figure;
t_layout = tiledlayout(2, 1, 'TileSpacing', 'compact');
title(t_layout, 'Chirp 量化位元數對 DFrFT 準確度之影響', 'FontWeight', 'bold', 'FontSize', 14);

nexttile;
plot(bit_range, rmse_errors, '-ob', 'LineWidth', 2, 'MarkerFaceColor', 'b');
title('均方根誤差 (RMSE) 趨勢'); ylabel('RMSE'); grid on; xticks(bit_range);

nexttile;
plot(bit_range, max_errors, '-sr', 'LineWidth', 2, 'MarkerFaceColor', 'r');
yline(2, '--k', 'RMSE = 2 門檻', 'LabelHorizontalAlignment', 'left', 'LineWidth', 1.5);
title('最大絕對誤差 (Max Absolute Error)'); xlabel('Chirp 量化位元數 (Bits)'); ylabel('Max Error'); grid on; xticks(bit_range);


% =========================================================================
% [第二部分] 回到現實：65537 費馬環極限 (乘積 <= 256) 的非對稱量化實驗
% =========================================================================
disp('======================================================');
disp('=== 65537 費馬環極限：RMSE 最佳化挑戰 (乘積 <= 256) ===');
disp('======================================================');

% 實驗 A: 傳統均分策略 (S1=6, S2=6, S3=6) -> 乘積 216 <= 256
S13_A = 6;  % C1 和 C3 倍率
S2_A  = 6;  % C2 倍率
Y_q_A = (ifft( fft(X_in .* quantize(C13_fl, S13_A)) .* fft(quantize(C2_fl_absorbed, S2_A)) ) * N) .* quantize(C13_fl, S13_A);
rmse_A = sqrt(mean(abs(Y_ideal - Y_q_A).^2));

disp(['[實驗 A] 傳統均分策略 (S1/3=', num2str(S13_A), ', S2=', num2str(S2_A), ')']);
disp(['   -> 總放大倍率: ', num2str(S13_A * S2_A * S13_A), ' (合法) | RMSE = ', num2str(rmse_A)]);
disp('--------------------------------------------------');

% 實驗 B: 頻域 All-in 非對稱策略 (S1/3=2, S2=64) -> 乘積 256 <= 256
S13_B = 2;  % C1 和 C3 只給 2 倍 (約 2-bit)
S2_B  = 64; % C2 獨佔 64 倍 (約 7-bit)
Y_q_B = (ifft( fft(X_in .* quantize(C13_fl, S13_B)) .* fft(quantize(C2_fl_absorbed, S2_B)) ) * N) .* quantize(C13_fl, S13_B);
rmse_B = sqrt(mean(abs(Y_ideal - Y_q_B).^2));

disp(['[實驗 B] 頻域 All-in 策略 (S1/3=', num2str(S13_B), ', S2=', num2str(S2_B), ')']);
disp(['   -> 總放大倍率: ', num2str(S13_B * S2_B * S13_B), ' (合法) | RMSE = ', num2str(rmse_B)]);

% 實驗 C: 激進型 All-in (如果輸入訊號稍小，容許稍微突破 256，比如 S1/3=3, S2=36 -> 乘積 324)
% (備註：因為 A_alpha 吸收進 C2 讓整體數值變小，有時稍微超標也不會溢位，需用 Verilog 實測)
S13_C = 3;  
S2_C  = 35; 
Y_q_C = (ifft( fft(X_in .* quantize(C13_fl, S13_C)) .* fft(quantize(C2_fl_absorbed, S2_C)) ) * N) .* quantize(C13_fl, S13_C);
rmse_C = sqrt(mean(abs(Y_ideal - Y_q_C).^2));

disp(['[實驗 C] 激進分配測試 (S1/3=', num2str(S13_C), ', S2=', num2str(S2_C), ')']);
disp(['   -> 總放大倍率: ', num2str(S13_C * S2_C * S13_C), ' (臨界邊緣) | RMSE = ', num2str(rmse_C)]);
disp('======================================================');
%%
% =========================================================================
% DFrFT 量化策略波形對比視覺化 (Waveform Comparison)
% =========================================================================
clc; clear; close all;

N = 16;
alpha = 0.5 * pi/2; 

% 1. 產生一組平滑且具代表性的 8-bit 輸入訊號 (加入一點低頻與高頻變化)
n_idx = 0:(N-1);
X_in = round(60 * cos(2*pi*n_idx/N) + 20 * sin(4*pi*n_idx/N)) + ...
       1j * round(40 * sin(2*pi*n_idx/N) - 15 * cos(6*pi*n_idx/N));

% 2. 理想浮點數 Chirp 與 A_alpha 補償
t = 0:(N-1);
C13_fl = exp(-0.5j * pi/2 * t.^2 * tan(alpha/2));
C2_fl  = exp(-0.5j * pi/2 * t.^2 * csc(alpha));
A_alpha = sqrt((1 - 1j*cot(alpha)) / (2*pi));

C2_fl_absorbed = C2_fl * A_alpha; 

% --- 理想解答 (Golden Model) ---
Y_ideal = (ifft( fft(X_in .* C13_fl) .* fft(C2_fl) ) * N) .* C13_fl * A_alpha;

% --- 策略 A：傳統均分 (S13 = 6, S2 = 6) ---
quantize = @(C, S) round(C * S) / S;
Y_q_A = (ifft( fft(X_in .* quantize(C13_fl, 6)) .* fft(quantize(C2_fl_absorbed, 6)) ) * N) .* quantize(C13_fl, 6);

% --- 策略 B：非對稱甜蜜點 (S13 = 2, S2 = 64) ---
Y_q_B = (ifft( fft(X_in .* quantize(C13_fl, 2)) .* fft(quantize(C2_fl_absorbed, 64)) ) * N) .* quantize(C13_fl, 2);

% 計算 RMSE 以供參考
rmse_A = sqrt(mean(abs(Y_ideal - Y_q_A).^2));
rmse_B = sqrt(mean(abs(Y_ideal - Y_q_B).^2));

% =========================================================================
% 繪圖比較
% =========================================================================
figure;
t_layout = tiledlayout(2, 1, 'TileSpacing', 'compact');
title(t_layout, 'DFrFT 不同量化策略之波形還原度對比', 'FontWeight', 'bold', 'FontSize', 14);

% --- 實部波形對比 ---
nexttile;
plot(n_idx, real(Y_ideal), 'r-', 'LineWidth', 3); hold on;
plot(n_idx, real(Y_q_A), 'b--o', 'LineWidth', 1.5, 'MarkerSize', 6);
plot(n_idx, real(Y_q_B), 'y-.s', 'LineWidth', 1.5, 'MarkerSize', 6);
title(['實部 (Real Part) 波形對比 | RMSE_A = ', num2str(round(rmse_A,2)), ', RMSE_B = ', num2str(round(rmse_B,2))]);
ylabel('Amplitude'); grid on;
legend('理想解答 (Float)', '策略A: 均分 (S=6, 6)', '策略B: 非對稱 (S=2, 64)', 'Location', 'best');

% --- 虛部波形對比 ---
nexttile;
plot(n_idx, imag(Y_ideal), 'r-', 'LineWidth', 3); hold on;
plot(n_idx, imag(Y_q_A), 'b--o', 'LineWidth', 1.5, 'MarkerSize', 6);
plot(n_idx, imag(Y_q_B), 'y-.s', 'LineWidth', 1.5, 'MarkerSize', 6);
title('虛部 (Imaginary Part) 波形對比');
xlabel('時間索引 (n)'); ylabel('Amplitude'); grid on;
%%
% =========================================================================
% DFrFT 蒙地卡羅全局 RMSE 最佳化 (Monte Carlo RMSE Grid Search)
% Objective: 針對 1000 組隨機輸入，尋找平均 RMSE 最小的量化組合
% =========================================================================
clc; clear; close all;

N = 16;
alpha = 0.5 * pi/2; 
num_tests = 1000;   % 蒙地卡羅測試次數

disp(['=== 啟動大規模 RMSE 蒙地卡羅搜尋 (測資數量: ', num2str(num_tests), ' 組) ===']);

% 1. 產生 1000 組隨機 8-bit 輸入訊號矩陣
X_re_in = randi([-128, 127], num_tests, N);
X_im_in = randi([-128, 127], num_tests, N);
X_in = X_re_in + 1j * X_im_in;

% 2. 產生理想浮點數 Chirp
t = 0:(N-1);
C13_fl = exp(-0.5j * pi/2 * t.^2 * tan(alpha/2));
C2_fl  = exp(-0.5j * pi/2 * t.^2 * csc(alpha));

% 3. 處理 A_alpha 吸收與產生 Golden Model 矩陣
A_alpha = sqrt((1 - 1j*cot(alpha)) / (2*pi));
C2_fl_absorbed = C2_fl * A_alpha; 

% 矩陣化算出 1000 組理想解答
Y_ideal = (ifft( fft(X_in .* C13_fl, [], 2) .* fft(C2_fl, [], 2), [], 2 ) * N) .* C13_fl * A_alpha;

% =========================================================================
% 網格搜索設定
% =========================================================================
MAX_PRODUCT = 1024; % 費馬環硬體極限：S13^2 * S2 <= 256
quantize = @(C, S) round(C * S) / S;

S13_range = 1 : 0.1 : 16;  
S2_range  = 1 : 0.1 : 16; 

best_rmse = inf;
best_S13 = 0;
best_S2 = 0;

plot_S13 = [];
plot_S2 = [];
plot_rmse = [];

disp('正在計算數萬筆組合的 RMSE，尋找最優解...');

% =========================================================================
% 啟動搜索迴圈
% =========================================================================
for S13 = S13_range
    for S2 = S2_range
        if (S13^2 * S2) <= MAX_PRODUCT
            
            % 矩陣化量化與硬體模擬
            C13_q = quantize(C13_fl, S13);
            C2_q  = quantize(C2_fl_absorbed, S2);
            Y_q = (ifft( fft(X_in .* C13_q, [], 2) .* fft(C2_q, [], 2), [], 2 ) * N) .* C13_q;
            
            % 計算全部 16000 個點的總體均方根誤差 (RMSE)
            error_matrix = abs(Y_ideal - Y_q);
            current_rmse = sqrt(mean(error_matrix.^2, 'all')); 
            
            plot_S13(end+1) = S13;
            plot_S2(end+1)  = S2;
            plot_rmse(end+1) = current_rmse;
            
            if current_rmse < best_rmse
                best_rmse = current_rmse;
                best_S13 = S13;
                best_S2 = S2;
            end
        end
    end
end

% =========================================================================
% 印出最佳結果
% =========================================================================
disp('======================================================');
disp('🏆 多測資全局最低 RMSE 參數配置找到！');
disp([' -> 最佳 S1/3 倍率 (共用 LUT): ', num2str(best_S13)]);
disp([' -> 最佳 S2 倍率: ', num2str(best_S2)]);
disp([' -> 總放大倍率: ', num2str(best_S13^2 * best_S2), ' (<= ', num2str(MAX_PRODUCT), ')']);
disp([' -> 達成最低全局 RMSE: ', num2str(best_rmse)]);
disp('======================================================');

% =========================================================================
% 繪製專業熱力圖
% =========================================================================
figure;
t_layout = tiledlayout(1, 1, 'TileSpacing', 'compact');
title(t_layout, '硬體資源極限與全局 RMSE 蒙地卡羅熱力分佈', 'FontWeight', 'bold', 'FontSize', 14);

nexttile;
scatter(plot_S13, plot_S2, 12, plot_rmse, 'filled');
colormap('turbo'); 
c = colorbar;
c.Label.String = '全局 RMSE 誤差 (越小越好)';

hold on;
S13_curve = linspace(1, max(S13_range), 100);
S2_curve = MAX_PRODUCT ./ (S13_curve.^2);
plot(S13_curve, S2_curve, 'r--', 'LineWidth', 2);

plot(best_S13, best_S2, 'p', 'MarkerSize', 18, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'w', 'LineWidth', 1.5);
text(best_S13 + 0.3, best_S2, ['\leftarrow 最佳解 (RMSE=', num2str(round(best_rmse,2)), ')'], 'Color', 'k', 'FontWeight', 'bold');

xlabel('S_{13} 放大倍率');
ylabel('S_2 放大倍率');
xlim([min(S13_range), max(S13_range)]);
ylim([min(S2_range), max(S2_range)]);
legend('搜索點 (顏色代表 RMSE)', '硬體極限邊界', '最佳甜蜜點', 'Location', 'northeast');
grid on;
%%
% =========================================================================
% DFrFT 端到端硬體加解密驗證 (End-to-End Hardware Crypto Simulation)
% 目的：計算「原始輸入」與「硬體加密再解密後」的真實系統 RMSE
% =========================================================================
clc; clear; close all;

N = 16;
Fq = 65537;
alpha = 0.5 * pi/2; 

% 1. 產生 8-bit 輸入訊號 (Original Input)
n_idx = 0:(N-1);
X_re_in = round(50 * cos(2*pi*n_idx/N) + 20); 
X_im_in = round(30 * sin(2*pi*n_idx/N) - 10);
X_in = X_re_in + 1j * X_im_in;

% 2. 產生浮點數 Chirp 與 A_alpha 吸收
t = 0:(N-1);
C13_fl = exp(-0.5j * pi/2 * t.^2 * tan(alpha/2));
C2_fl  = exp(-0.5j * pi/2 * t.^2 * csc(alpha));
A_alpha = sqrt((1 - 1j*cot(alpha)) / (2*pi));
C2_fl_absorbed = C2_fl * A_alpha; 

% =========================================================================
% 階段一：Python 離線預算 (產生加密 ROM 與解密反元素 ROM)
% =========================================================================
% 我們採用非對稱量化策略 (S13=2, S2=64) 作為示範
S13 = 2; S2 = 64;

% 【關鍵修正】：硬體 ROM 裡面只能存「純整數」，絕對不能除以 S！
quantize_int = @(C, S) round(C * S); 

% [加密 ROM]: 轉為 17-bit Fermat 整數
C13_enc_rom = zeros(1, N);
C2_enc_rom  = zeros(1, N);
for i = 1:N
    q13 = quantize_int(C13_fl(i), S13);
    q2  = quantize_int(C2_fl_absorbed(i), S2);
    
    % 強制轉型為 int64，滿足 MATLAB bitshift 的嚴格要求
    re_13 = int64(to_fermat(real(q13)));
    im_13 = int64(to_fermat(imag(q13)));
    C13_enc_rom(i) = mod_fold(re_13 + bitshift(im_13, 8));
    
    re_2 = int64(to_fermat(real(q2)));
    im_2 = int64(to_fermat(imag(q2)));
    C2_enc_rom(i)  = mod_fold(re_2  + bitshift(im_2, 8));
end

% [解密 ROM]: 計算模數 65537 下的乘法反元素 (Modular Multiplicative Inverse)
C13_dec_rom = zeros(1, N);
C2_dec_rom  = zeros(1, N);
for i = 1:N
    C13_dec_rom(i) = mod_inverse(C13_enc_rom(i), Fq);
    C2_dec_rom(i)  = mod_inverse(C2_enc_rom(i),  Fq);
end

% =========================================================================
% 階段二：硬體加密 (Hardware Encryption Flow)
% =========================================================================
% 0. 輸入轉換 (Concat)
HW_SRAM = zeros(1, N);
for i = 1:N
    HW_SRAM(i) = mod_fold(to_fermat(X_re_in(i)) + bitshift(to_fermat(X_im_in(i)), 8));
end

% 1. 乘 ROM 13 -> FNT -> 乘 ROM 2 -> IFNT (含 N_inv) -> 乘 ROM 13
for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), C13_enc_rom(i)); end
HW_SRAM = run_fnt_stages(bit_reverse_array(HW_SRAM), 'forward');

for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), C2_enc_rom(i)); end
HW_SRAM = run_fnt_stages(bit_reverse_array(HW_SRAM), 'inverse');

N_inv = 61441; % 16^(-1) mod 65537
for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), N_inv); end

for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), C13_enc_rom(i)); end
Ciphertext_SRAM = HW_SRAM; % 這是 17-bit 的密文！

% =========================================================================
% 階段三：硬體解密 (Hardware Decryption Flow) - 使用反元素 ROM
% =========================================================================
% 硬體流向完全倒過來：乘 Dec_ROM 13 -> FNT -> 乘 Dec_ROM 2 -> IFNT -> 乘 Dec_ROM 13
HW_SRAM = Ciphertext_SRAM;

for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), C13_dec_rom(i)); end
HW_SRAM = run_fnt_stages(bit_reverse_array(HW_SRAM), 'forward');

for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), C2_dec_rom(i)); end
HW_SRAM = run_fnt_stages(bit_reverse_array(HW_SRAM), 'inverse');

for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), N_inv); end

for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), C13_dec_rom(i)); end

% =========================================================================
% 階段四：解碼輸出與真實 RMSE 計算
% =========================================================================
X_out_re = zeros(1, N);
X_out_im = zeros(1, N);
for i = 1:N
    re_uint = bitand(HW_SRAM(i), 255); 
    im_uint = bitshift(HW_SRAM(i), -8);
    X_out_re(i) = from_2s_comp(re_uint);
    X_out_im(i) = from_2s_comp(im_uint);
end

% 計算原始輸入與解密輸出的真實 RMSE
final_error_re = abs(X_re_in - X_out_re);
final_error_im = abs(X_im_in - X_out_im);
true_rmse_re = sqrt(mean(final_error_re.^2));
true_rmse_im = sqrt(mean(final_error_im.^2));

disp('=== 端到端系統解密完成 ===');
disp(['實部真實還原 RMSE: ', num2str(true_rmse_re)]);
disp(['虛部真實還原 RMSE: ', num2str(true_rmse_im)]);
disp('最大絕對誤差 (Real):'); disp(max(final_error_re));

% =========================================================================
% 繪圖對比：Original Input vs. Decrypted Output
% =========================================================================
figure;
t_layout = tiledlayout(2, 1, 'TileSpacing', 'compact');
title(t_layout, '端到端硬體加解密波形還原度 (End-to-End Recovery)', 'FontWeight', 'bold', 'FontSize', 14);

nexttile;
plot(n_idx, X_re_in, 'b-', 'LineWidth', 2); hold on;
plot(n_idx, X_out_re, 'r--o', 'LineWidth', 1.5);
title('實部還原波形'); legend('原始輸入 (Original)', '硬體解密 (Decrypted)', 'Location', 'best'); grid on;

nexttile;
plot(n_idx, X_im_in, 'b-', 'LineWidth', 2); hold on;
plot(n_idx, X_out_im, 'r--s', 'LineWidth', 1.5);
title('虛部還原波形'); xlabel('時間索引 (n)'); grid on;

% =========================================================================
% 硬體等效函式區
% =========================================================================
% [新增] 擴展歐幾里得演算法求模數反元素
function inv_val = mod_inverse(a, m)
    [g, x, ~] = gcd(a, m);
    if g ~= 1
        error(['找不到反元素! a=', num2str(a), ', m=', num2str(m)]);
    else
        inv_val = mod(x, m);
    end
end

% 以下保留原本的模組 (mod_fold, fermat_mult, run_fnt_stages, fermat_shift, bit_reverse_array, to_fermat, from_2s_comp)
function out = mod_fold(P)
    P_low = bitand(P, 65535); P_high = bitshift(P, -16);
    result = P_low - P_high;
    if result < 0, result = result + 65537; elseif result >= 65537, result = result - 65537; end
    out = result;
end
function out = fermat_mult(A, B), out = mod_fold(A * B); end
function out = fermat_shift(B, s)
    s = mod(s, 32);
    if s >= 16, shift_amt = s - 16; negate = true; else, shift_amt = s; negate = false; end
    res = mod_fold(bitshift(B, shift_amt));
    if negate, if res == 0, out = 0; else, out = 65537 - res; end
    else, out = res; end
end
function SRAM = run_fnt_stages(SRAM, mode)
    N = 16; stages = log2(N);
    for stg = 0:(stages-1)
        stride = 2^stg; chunk = 2^(stg+1);
        for i = 0:(N-1)
            if mod(i, chunk) < stride
                idxA = i + 1; idxB = i + stride + 1;
                A = SRAM(idxA); B = SRAM(idxB);
                k = mod(i, chunk) * (N / chunk);
                if strcmp(mode, 'forward'), shift_s = mod(2 * k, 32); 
                else, shift_s = mod(2 * (16 - k), 32); end
                B_shifted = fermat_shift(B, shift_s);
                SRAM(idxA) = mod_fold(A + B_shifted);
                temp_diff = A - B_shifted;
                if temp_diff < 0, temp_diff = temp_diff + 65537; end
                SRAM(idxB) = temp_diff;
            end
        end
    end
end
function out_array = bit_reverse_array(in_array)
    out_array = zeros(1, 16);
    for i = 0:15
        bin_str = dec2bin(i, 4); rev_str = reverse(bin_str);
        out_array(bin2dec(rev_str) + 1) = in_array(i + 1);
    end
end
function f_val = to_fermat(val), if val < 0, f_val = 65537 + val; else, f_val = val; end, end
function val = from_2s_comp(uint_val), if uint_val > 127, val = uint_val - 256; else, val = uint_val; end, end