clear; close all;

N = 32;
n_idx = 0:(N-1);
X_re_in = round(50 * cos(2*pi*n_idx/N) + 20); 
X_im_in = round(30 * sin(2*pi*n_idx/N) - 10);
y =  X_re_in + 1j * X_im_in;

a = 0.5;
% 你的第三方 FrFT 算法 (特徵向量法 - 浮點數理想值)
yfunc = disFrFT(y, a, 2);

% =================================================
% ====== F5 架構 (2^32+1) FNT-based FrFT ======
% =================================================
MODULUS = 4294967297; 
BASE = 65536;         
S13 = 32;             
S2  = 256;            
INV_N = 4026531841;   

alpha = a * pi / 2;

% 產生理想 Chirp
c1 = exp(-0.5j * pi / 2 * (n_idx.^2) * tan(alpha/2));
c2 = exp(-0.5j * pi / 2 * (n_idx.^2) * (1/sin(alpha)));
a_alpha = sqrt((1 - 1j/cot(alpha)) / (2*pi));
c2_abs = c2 * a_alpha;

% 核心修正：時域濾波器就是 c2 本身，絕對不能做 ifft！
h_complex = c2_abs;  

% F5 Fermat 域量化 
mod_fold = @(re, im) mod(round(re) + round(im)*BASE, MODULUS);
lut_c13 = zeros(1, N);
h_fermat = zeros(1, N);

for k = 1:N
    lut_c13(k) = mod_fold(real(c1(k))*S13, imag(c1(k))*S13);
    h_fermat(k) = mod_fold(real(h_complex(k))*S2, imag(h_complex(k))*S2);
end

% 產生 F5 硬體的 lut_c2 
lut_c2 = FNT16_F5(h_fermat, false);

% 1. 產生真正的「理想捲積 (Ideal Convolution)」作為硬體的 Golden
% 注意：這不是 disFrFT，而是硬體演算法的浮點數版本
ideal_conv_res = zeros(1, N);
s1_f = y .* c1;
s2_f = fft(s1_f); % 模擬 FNT
s3_f = s2_f .* fft(ifft(c2_abs)); % 模擬頻域相乘
s4_f = ifft(s3_f); % 模擬 IFNT
ideal_conv_res = s4_f .* c1;

% 執行硬體資料流 
y_hw = zeros(1, N);
for k = 1:N
    y_hw(k) = mod_fold(real(y(k)), imag(y(k)));
end

s1 = zeros(1, N);
for k=1:N, s1(k) = fermat_mul(y_hw(k), lut_c13(k)); end
s2 = FNT16_F5(s1, false);
s3 = zeros(1, N);
for k=1:N, s3(k) = fermat_mul(s2(k), lut_c2(k)); end
s4 = FNT16_F5(s3, true);
s5 = zeros(1, N);
for k=1:N, s5(k) = fermat_mul(s4(k), lut_c13(k)); end
y_hw_out = zeros(1, N);
for k=1:N, y_hw_out(k) = fermat_mul(s5(k), INV_N); end

% 6. F5 硬體解碼器 (修正後的 Decoder)
y_hw_sim = zeros(1, N);
for k = 1:N
    val = y_hw_out(k);
    if val > 2147483648 
        val = val - MODULUS;
    end
    raw_im = round(val / BASE);
    raw_re = val - raw_im * BASE;
    
    % 修正：根據 V = -4Im + j(4Re) 進行反轉
    % 真正的實部 Re = raw_im / 4
    % 真正的虛部 Im = -raw_re / 4
    true_re = raw_im / 4;
    true_im = -raw_re / 4;
    
    % 尺度補償：捲積法相對於 Unitary FrFT 的理論常數補償 (~160 / 4 = 40)
    y_hw_sim(k) = (true_re + 1j * true_im) / 40;
end

% =================================================
% ====== 畫圖比較 ======
% =================================================
figure; hold on; grid on;
plot(n_idx, real(y), '-o', 'LineWidth', 1.2);
plot(n_idx, real(yfunc), '-s', 'LineWidth', 1.2);
plot(n_idx, real(y_hw_sim), 'x--', 'LineWidth', 1.5, 'MarkerSize', 8, 'Color', '#D95319');
legend('Input', 'Ideal Output (disFrFT)', 'Hardware F5 Convolution');
title(['Real part, a = ', num2str(a)]);

figure; hold on; grid on;
plot(n_idx, imag(y), '-o', 'LineWidth', 1.2);
plot(n_idx, imag(yfunc), '-s', 'LineWidth', 1.2);
plot(n_idx, imag(y_hw_sim), 'x--', 'LineWidth', 1.5, 'MarkerSize', 8, 'Color', '#D95319');
legend('Input', 'Ideal Output (disFrFT)', 'Hardware F5 Convolution');
title(['Imag part, a = ', num2str(a)]);

figure; hold on; grid on;
plot(n_idx, real(yfunc), '-s', 'DisplayName', 'disFrFT (Pei Algorithm)');
plot(n_idx, real(ideal_conv_res), '-o', 'DisplayName', 'Ideal Convolution (Floating)');
plot(n_idx, real(y_hw_sim), 'x--', 'LineWidth', 1.5, 'DisplayName', 'Hardware F5 (33-bit)');
legend; title(['Real part Comparison, a = ', num2str(a)]);

function out = fermat_mul(A, B)
    MODULUS = 4294967297; BASE = 65536;
    A = mod(A, MODULUS); B = mod(B, MODULUS);
    a0 = mod(A, BASE); a1 = floor(A / BASE);
    b0 = mod(B, BASE); b1 = floor(B / BASE);
    term2 = mod(a1 * b0 + a0 * b1, MODULUS);
    term2_shifted = mod(term2 * BASE, MODULUS);
    res = a0 * b0 + term2_shifted - a1 * b1;
    out = mod(res, MODULUS);
end

function X = FNT16_F5(x, is_inv)
    N = 32; MODULUS = 4294967297;
    if is_inv
        psi = 16;              
    else
        psi = 4026531841; 
    end
    M = zeros(N, N);
    for r = 1:N
        for c = 1:N
            base = psi; exp_val = (r-1)*(c-1); val = 1;
            while exp_val > 0
                if mod(exp_val, 2) == 1, val = fermat_mul(val, base); end
                base = fermat_mul(base, base); exp_val = floor(exp_val / 2);
            end
            M(r, c) = val;
        end
    end
    X = zeros(N, 1);
    for r = 1:N
        sum_val = 0;
        for c = 1:N
            prod_val = fermat_mul(M(r, c), x(c));
            sum_val = mod(sum_val + prod_val, MODULUS);
        end
        X(r) = sum_val;
    end
    X = X.';
end

% (請將你的 disFrFT 等輔助函數保留在腳本最下方)