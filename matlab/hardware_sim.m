% =========================================================================
% DFrFT [8-bit Real Input + 3-bit Chirp] 位元級 (Bit-Level) 終極驗證
% =========================================================================
clc; clear; close all;

N = 32;
Fq = 65537;
alpha = 0.5 * pi/2; 

disp('=== 啟動 DFrFT 位元級硬體模擬 (8-bit Real, 3-bit Chirp) ===');

% 1. 產生 8-bit 純實數輸入 (Real Only, Imag = 0)
n_idx = 0:(N-1);
X_re_in = round(100 * cos(2*pi*n_idx/N) + 10 * sin(4*pi*n_idx/N)); % -110 ~ 110
X_im_in = zeros(1, N); % 虛部嚴格為 0

% 2. 產生理想浮點數 Chirp 並吸收 A_alpha
t = 0:(N-1);
C13_fl = exp(-0.5j * pi/2 * t.^2 * tan(alpha/2));
C2_fl  = exp(-0.5j * pi/2 * t.^2 * csc(alpha));
A_alpha = sqrt((1 - 1j*cot(alpha)) / (2*pi));
C2_fl_absorbed = C2_fl * A_alpha; 

% =========================================================================
% 階段一：硬體 ROM 燒錄準備 (3-bit 量化)
% =========================================================================
% 3-bit signed 整數的極值約為 -4 ~ 3，我們取放大倍率 S = 3
S = 3; 

% 強制純整數運算
quantize_int = @(C, S) round(C * S); 

C13_enc_rom = zeros(1, N, 'int64');
C2_enc_rom  = zeros(1, N, 'int64');
C13_dec_rom = zeros(1, N, 'int64');
C2_dec_rom  = zeros(1, N, 'int64');

for i = 1:N
    q13 = quantize_int(C13_fl(i), S);
    q2  = quantize_int(C2_fl_absorbed(i), S);
    
    % 將實部與虛部轉為 Fermat 格式並拼接 (Bit-shift)
    re_13 = int64(to_fermat(real(q13)));
    im_13 = int64(to_fermat(imag(q13)));
    C13_enc_rom(i) = mod_fold(re_13 + bitshift(im_13, 8));
    
    re_2 = int64(to_fermat(real(q2)));
    im_2 = int64(to_fermat(imag(q2)));
    C2_enc_rom(i)  = mod_fold(re_2  + bitshift(im_2, 8));
    
    % 計算解密用的反元素 ROM
    C13_dec_rom(i) = mod_inverse(C13_enc_rom(i), Fq);
    C2_dec_rom(i)  = mod_inverse(C2_enc_rom(i),  Fq);
end

% =========================================================================
% 階段二：硬體加密 (Bit-Level Encryption)
% =========================================================================
% 初始拼接 (因為 X_im_in 是 0，所以其實只是 X_re_in 轉 fermat)
HW_SRAM = zeros(1, N, 'int64');
for i = 1:N
    HW_SRAM(i) = mod_fold(to_fermat(X_re_in(i)) + bitshift(to_fermat(X_im_in(i)), 8));
end

% FSM 加密排程
for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), C13_enc_rom(i)); end
HW_SRAM = run_fnt_stages(bit_reverse_array(HW_SRAM), 'forward');

for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), C2_enc_rom(i)); end
HW_SRAM = run_fnt_stages(bit_reverse_array(HW_SRAM), 'inverse');

N_inv = int64(63489); % 32^(-1) mod 65537
for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), N_inv); end

for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), C13_enc_rom(i)); end

Ciphertext = HW_SRAM; % 這是包含雜訊、位元交疊的 17-bit 密文！

% =========================================================================
% 階段三：硬體解密 (Bit-Level Decryption)
% =========================================================================
HW_SRAM = Ciphertext;

% FSM 解密排程 (注意順序與 ROM 的替換)
for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), C13_dec_rom(i)); end
HW_SRAM = run_fnt_stages(bit_reverse_array(HW_SRAM), 'forward');

for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), C2_dec_rom(i)); end
HW_SRAM = run_fnt_stages(bit_reverse_array(HW_SRAM), 'inverse');

for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), N_inv); end

for i=1:N, HW_SRAM(i) = fermat_mult(HW_SRAM(i), C13_dec_rom(i)); end

% =========================================================================
% 階段四：Bit-Slicing 與誤差計算
% =========================================================================
X_out_re = zeros(1, N);
for i = 1:N
    % 完美的 Bit-Slicing：此時位元交疊已解除，安全切下低 8-bit
    re_uint = bitand(HW_SRAM(i), 255); 
    X_out_re(i) = from_2s_comp(re_uint);
end

% 計算真實硬體 RMSE
final_error = abs(X_re_in - X_out_re);
true_rmse = sqrt(mean(final_error.^2));

disp('=== 驗證完成 ===');
disp(['🏆 8-bit Real 端到端硬體還原 RMSE: ', num2str(true_rmse)]);
if true_rmse == 0
    disp('✨ 結論：完美的無損加解密！位元級驗證 100% 通過！');
else
    disp('⚠️ 結論：出現誤差，請檢查硬體架構極限。');
end

% =========================================================================
% 繪圖驗證
% =========================================================================
figure('Name', '8-bit Real / 3-bit Chirp 驗證');
plot(n_idx, X_re_in, 'r-', 'LineWidth', 4); hold on;
plot(n_idx, X_out_re, 'b--o', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r');
title(['DFrFT 實部波形端到端還原 (RMSE = ', num2str(true_rmse), ')'], 'FontWeight', 'bold', 'FontSize', 14);
legend('原始輸入 8-bit', '硬體反元素解密輸出', 'Location', 'best');
xlabel('時間索引 (n)'); ylabel('振幅 (Amplitude)'); grid on;

% =========================================================================
% 硬體等效函式區 (使用 int64 確保 Bit-level 精度)
% =========================================================================
function inv_val = mod_inverse(a, m)
    [g, x, ~] = gcd(double(a), double(m));
    if g ~= 1, error('找不到反元素!'); else, inv_val = int64(mod(x, double(m))); end
end
function out = mod_fold(P)
    P = int64(P);
    P_low = bitand(P, int64(65535)); 
    P_high = bitshift(P, -16);
    result = P_low - P_high;
    if result < 0, result = result + 65537; elseif result >= 65537, result = result - 65537; end
    out = result;
end
function out = fermat_mult(A, B), out = mod_fold(int64(A) * int64(B)); end
function out = fermat_shift(B, s)
    s = mod(int64(s), int64(32));
    if s >= 16, shift_amt = s - 16; negate = true; else, shift_amt = s; negate = false; end
    res = mod_fold(bitshift(int64(B), shift_amt));
    if negate, if res == 0, out = int64(0); else, out = int64(65537) - res; end
    else, out = res; end
end
function SRAM = run_fnt_stages(SRAM, mode)
    N = numel(SRAM); stages = log2(N);
    for stg = 0:(stages-1)
        stride = 2^stg; chunk = 2^(stg+1);
        for i = 0:(N-1)
            if mod(i, chunk) < stride
                idxA = i + 1; idxB = i + stride + 1;
                A = SRAM(idxA); B = SRAM(idxB);
                k = mod(i, chunk) * (N / chunk);
                if strcmp(mode, 'forward'), shift_s = mod(2 * k, 32); else, shift_s = mod(2 * (16 - k), 32); end
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
    N = numel(in_array);
    bits = log2(N);
    out_array = zeros(1, N, 'int64');
    for i = 0:(N-1)
        bin_str = dec2bin(i, bits); rev_str = reverse(bin_str);
        out_array(bin2dec(rev_str) + 1) = in_array(i + 1);
    end
end
function f_val = to_fermat(val), if val < 0, f_val = int64(65537 + val); else, f_val = int64(val); end, end
function val = from_2s_comp(uint_val), if uint_val > 127, val = double(uint_val) - 256; else, val = double(uint_val); end, end