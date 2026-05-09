# DFrFT Hardware / Simulation Project

## 模擬階段結論

\* 自己寫的，要更詳細去叫 Gemini Pro 直接看 code

---

# 新方法

```python
input: x_c = x_real + 1j * x_imag

angle_param = key * np.pi / 128
phi = -k_orders * angle_param

Lambda_alpha = np.exp(1j * phi)

output = V_float @ (Lambda_alpha * (V_float.T @ x_c))
```

- Eigen value: `Lambda_alpha`
  - Use CORDIC

- `V_float`
  - fixed / constant / determined by N
  - Use customized matrix-vector multiplier

---

# 檔案們

# 純軟體模擬

## `sim.py`

重點是找出好的 matrix `V`，使得作出的 FrFT 轉換符合以下特性：

- 轉角度是 `pi/2` 的時候和 FFT 的結果很像
- 並且以下誤差夠小

```txt
=== DFrFT 數學特性嚴謹驗證 ===

[1] 加法性誤差 (0.33 + 0.45 vs 0.78): 2.30e-14
[2] 可逆性誤差 (轉 0.87 再轉 -0.87): 1.62e-14
[3] 能量守恆誤差 (|Input|^2 vs |Output|^2): 4.26e-14
[4a] a=0 誤差 (與原訊號比): 1.93e-14
[4b] a=2 誤差 (與時間反轉比): 2.59e-11
[4c] a=3 誤差 (與 IFFT 比): 1.83e-11
```

這邊角度 = `a * pi / 2` 哈哈

---

找 `V` 經歷了很多測試，最新的是：

```python
get_ultimate_V_and_k()
```

會回傳：

```python
k_order
```

代表要算 eigen vector 要帶入的 index。

目前是：

```python
0, 1, 2, ..., 30, 32
```

（非打錯，就這樣）

---

### PROBLEM

搞懂找 `V` 的數學。

目前感覺和：

- perturbation
- 加入擾動
- eigen structure

之類的東西有關。

---

## `compare.py`

和之前 chirp convolution / chirp multiplication 的結果比，是爛的。

### PROBLEM

可以試著改到一樣。

---

# 硬體模擬

## `hw_sim.py`

對 1D 信號做 DFrFT。

有考慮：

- hardware pipeline
- 中間 bit 數

但：

### overflow 問題目前沒有完整考慮

真的要模擬的話可以：

- 多對數值套 `is_signed()`
- 確認 bit 數
- 防止 overflow

---

最後輸出的：

- LSB 代表 1

原因是：

中間有做階段性的 right shift，把：

- CORDIC quantization scale
- V_float quantization scale

等東西消掉。

但最後怎麼設計還不一定，所以模擬也可以改。

---

檔案最上面有：

```python
error_sweep = True
config_sweep = True
```

---

## `error_sweep`

輸出圖：

```txt
error_sweep_eigen_hw.png
```

用途：

- 對一個隨機 input 畫 error 圖

---

## `config_sweep`

輸出圖：

```txt
heatmap_grid_search_3pannels.png
```

用途：

- 改變 CORDIC stage
- 改變 V 的 bit 數
- 看 output 的 MSE 影響

---

目前觀察：

差異很小。

感覺是因為：

中間 right shift 掉不少 fractional bits，

所以最後差異沒有很明顯。

### PROBLEM

可以研究這邊。

---

另外檔案還會輸出：

```txt
V_float.txt
V_ops.txt
V_q.txt
```

---

## `V_q.txt`

quantize 後的 matrix。

---

## `V_ops.txt`

把數值變成：

- 2-stage
- 2 的密次乘法

因此可以用：

- shift
- 最多一個 adder

來實現（目前是這樣）。

格式：

```txt
(sign, shift)
```

如果都是 0：

代表 quantize 後變成 0。

---

# `2D_hw_sim.py`

試試看對 2D 圖做加解密。

有考慮 hardware pipeline。

---

執行：

```bash
python 2D_hw_sim.py --img_path test.jpg
```

可以對 `test.jpg` 分塊做。

但跑頗久。

---

輸出圖：

```txt
2d_encryption_test.png
```

---

### PROBLEM

解密的時候：

我直接把 output（目前應該約 2x bit）傳回去，

所以 input 不再只是 8-bit。

如果真的要做解密硬體：

需要考慮這個彈性。

---

目前沒有 fully inversible：

只是因為硬體各階段的 quantization。

如果套理論：

其實可以幾乎完美還原。

---

# `cordic_sim.py`

只考慮：

- eigen vector
- stage 數量
- out_shift

對誤差的影響。

---

但因為：

theoretical 那邊也拉到同樣 bit 數，

所以目前沒啥參考價值。

---

輸出圖：

```txt
Heat_Eigne_Match.png
```

---

# 可以參考的 RTL

## `./CORDIC/cordic_sincos.v`

重點：

- 輸入 phase：signed 16-bit
- `+16384` 代表 `pi/2`
- `pi` 代表 `2^15`
- 剛好繞一圈 `2pi`

因此和 signed integer 特性相符。

---

CORDIC convergence region：

```txt
[-pi/2, +pi/2]
```

---

中間數值：

- 16-bit

因此：

- `K_INV`
- `arctan LUT`

也是依此決定。

---

可以改：

```txt
STAGE 數量
```

目前最多：

```txt
12
```

---

輸出：

```txt
16 - output_shift (=7) = 9 bit
```

的：

- cos value
- sin value

---

## `./CORDIC/Chirp_generator.v`

之前殘骸。

可以大概看一下。

---

# 其他

## `plot_utility.py`

畫 heat map 的函數工具。
