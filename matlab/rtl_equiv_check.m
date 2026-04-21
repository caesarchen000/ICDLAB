% =========================================================================
% RTL-equivalent vs double-domain check (N=32, mod 2^32+1)
% This script helps separate "domain mismatch" from real RTL bugs.
% =========================================================================
clc; clear; close all;

N = 32;
MODULUS = uint64(4294967297); % 2^32 + 1
BASE = uint64(65536);         % j mapping base used by RTL/LUT flow
PSI = uint64(4);              % principal 32nd root in this design
SCALE = 127;                  % same LUT quantization scale used in lut_gen.py
key = int32(50);              % test key

n = 0:(N-1);
alpha = double(key) / 64.0 * pi / 2;

% Signed 8-bit input (real + imag), deterministic pattern
x_re = int32(round(60*cos(2*pi*n/N) + 20*sin(6*pi*n/N)));
x_im = int32(round(40*sin(2*pi*n/N) - 15*cos(4*pi*n/N)));
x_re = max(min(x_re, 127), -128);
x_im = max(min(x_im, 127), -128);

% Chirps (same formula family as LUT generator)
c13 = exp(-1j * pi / N * (n.^2) * tan(alpha/2));
c2  = exp( 1j * pi / N * (n.^2) * csc(alpha));

q13_re = round(real(c13) * SCALE);
q13_im = round(imag(c13) * SCALE);
q2_re  = round(real(c2)  * SCALE);
q2_im  = round(imag(c2)  * SCALE);

% Build integer-domain chirps exactly as finite-field packed values
c13_fq = zeros(1, N, "uint64");
c2_fq  = zeros(1, N, "uint64");
for i = 1:N
    c13_fq(i) = make_invertible(complex_to_fq(q13_re(i), q13_im(i), MODULUS, BASE), MODULUS);
    c2_fq(i)  = make_invertible(complex_to_fq(q2_re(i),  q2_im(i),  MODULUS, BASE), MODULUS);
end
c2_fnt = fnt_mod(c2_fq, PSI, MODULUS);

% --------------------- Integer / mod-domain model ------------------------
x_fq = zeros(1, N, "uint64");
for i = 1:N
    x_fq(i) = complex_to_fq(x_re(i), x_im(i), MODULUS, BASE);
end

s1 = mod_mul_vec(x_fq, c13_fq, MODULUS);
s2 = fnt_mod(s1, PSI, MODULUS);
s3 = mod_mul_vec(s2, c2_fnt, MODULUS);
s4 = ifnt_mod(s3, PSI, MODULUS);
s5 = mod_mul_vec(s4, c13_fq, MODULUS);
cipher_int = s5;

% --------------------- Double-domain (quantized chirps) ------------------
x_double = double(x_re) + 1j*double(x_im);
c13_q = double(q13_re) + 1j*double(q13_im);
c2_q  = double(q2_re)  + 1j*double(q2_im);

% Same high-level pipeline, but in floating-point complex domain
y_double = (ifft(fft(x_double .* c13_q) .* fft(c2_q)) * N) .* c13_q;

% Pack double output into same integer field format for direct compare
cipher_double_packed = zeros(1, N, "uint64");
for i = 1:N
    cipher_double_packed(i) = complex_to_fq(round(real(y_double(i))), round(imag(y_double(i))), MODULUS, BASE);
end

% --------------------- Compare ------------------------
diff_mask = (cipher_int ~= cipher_double_packed);
num_diff = sum(diff_mask);

fprintf("N = %d\n", N);
fprintf("Different ciphertext words: %d / %d\n", num_diff, N);
if num_diff > 0
    idx = find(diff_mask, 1, "first");
    fprintf("First mismatch @ index %d\n", idx-1);
    fprintf("  int/mod   = 0x%09X\n", cipher_int(idx));
    fprintf("  double->fq= 0x%09X\n", cipher_double_packed(idx));
end
fprintf("This difference is expected when comparing different math domains.\n");

% Optional quick view
figure("Name", "Integer-vs-Double Domain Check");
stem(0:N-1, double(mod(cipher_int, 2^16)), "filled"); hold on;
stem(0:N-1, double(mod(cipher_double_packed, 2^16)));
grid on; legend("int/mod", "double packed");
title("Packed ciphertext low-16 trend (N=32)");

% =========================================================================
% Helpers
% =========================================================================
function v = complex_to_fq(re, im, MODULUS, BASE)
    re_mod = mod(int64(re), int64(MODULUS));
    im_mod = mod(int64(im), int64(MODULUS));
    v = uint64(mod(re_mod + im_mod * int64(BASE), int64(MODULUS)));
end

function g = gcd_u64(a, b)
    x = uint64(a); y = uint64(b);
    while y ~= 0
        t = mod(x, y);
        x = y;
        y = t;
    end
    g = x;
end

function v = make_invertible(v0, MODULUS)
    v = v0;
    while gcd_u64(v, MODULUS) ~= 1
        v = mod(v + 1, MODULUS);
    end
end

function c = mod_mul_vec(a, b, MODULUS)
    c = zeros(size(a), "uint64");
    for i = 1:numel(a)
        c(i) = uint64(mod(uint64(a(i)) * uint64(b(i)), MODULUS));
    end
end

function X = fnt_mod(x, psi, MODULUS)
    N = numel(x);
    X = zeros(1, N, "uint64");
    for k = 0:(N-1)
        acc = uint64(0);
        for n = 0:(N-1)
            tw = mod_pow(psi, uint64(n*k), MODULUS);
            acc = mod(acc + mod(uint64(x(n+1)) * tw, MODULUS), MODULUS);
        end
        X(k+1) = acc;
    end
end

function x = ifnt_mod(X, psi, MODULUS)
    N = numel(X);
    psi_inv = mod_inv(psi, MODULUS);
    n_inv = mod_inv(uint64(N), MODULUS);
    x = zeros(1, N, "uint64");
    for n = 0:(N-1)
        acc = uint64(0);
        for k = 0:(N-1)
            tw = mod_pow(psi_inv, uint64(n*k), MODULUS);
            acc = mod(acc + mod(uint64(X(k+1)) * tw, MODULUS), MODULUS);
        end
        x(n+1) = mod(acc * n_inv, MODULUS);
    end
end

function y = mod_pow(base, expn, modn)
    y = uint64(1);
    b = uint64(base);
    e = uint64(expn);
    while e > 0
        if bitand(e, 1) ~= 0
            y = mod(y * b, modn);
        end
        b = mod(b * b, modn);
        e = bitshift(e, -1);
    end
end

function inv = mod_inv(a, m)
    % Extended Euclid over doubles for portability (values are <= 2^33)
    aa = double(a); mm = double(m);
    t = 0; newt = 1;
    r = mm; newr = aa;
    while newr ~= 0
        q = floor(r / newr);
        temp = newt; newt = t - q * newt; t = temp;
        temp = newr; newr = r - q * newr; r = temp;
    end
    if r ~= 1
        error("mod_inv: not invertible");
    end
    if t < 0
        t = t + mm;
    end
    inv = uint64(t);
end
