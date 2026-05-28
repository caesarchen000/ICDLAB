# RTL RGB image flow (`tb_2d_rgb.v` + `rtl_rgb_flow.py`)

1. **split** — `sim_image_resized.png` -> `pattern/img_r.txt`, `img_g.txt`, `img_b.txt` (decimal 0–255, one per line)
2. **RTL** — per channel: row enc -> `*_enc1d.txt`, col enc -> `*_enc2d.txt`, col dec -> `*_dec1d.txt`, row dec -> `*_dec2d.txt`  
   Input: `pixel - 128` (8-bit signed real, imag=0). Between passes: **saturate** 11-bit to ±127 (no `>>3`).
3. **merge** — `r/g/b_dec2d.txt` -> `rtl_rgb_decrypted.png`

```bash
cd 00_TESTBED/gen
python3 new_hw_sim.py
python3 new_hw_sim.py --max 320 --fixed-key
python3 rtl_rgb_flow.py split
python3 rtl_rgb_flow.py golden
cd ../../01_RTL
bash run_tb_2d_rgb.sh
cd ../00_TESTBED/gen
python3 rtl_rgb_flow.py check
python3 rtl_rgb_flow.py merge --enc-preview
python3 rtl_rgb_flow.py show
```

Key **40** fixed; decrypt order: cols then rows (inverse of encrypt).

### 11-bit inter-pass (wider storage, closer to `new_hw_sim` 9-bit sim)

CHIP `IOPORT_IN_W=22` (`tb_2d_rgb_11.v`): `{imag[10:0], real[10:0]}`, saturate to 11-bit between passes.

```bash
cd 01_RTL
bash run_tb_2d_rgb_11.sh
cd ../00_TESTBED/gen
python3 rtl_rgb_flow.py --in11 golden
python3 rtl_rgb_flow.py --in11 check
python3 rtl_rgb_flow.py --in11 merge --enc-preview
```

Outputs: `pattern/*_enc1d_11.txt` ... `rtl_rgb_decrypted_11.png`

Legacy 8-bit inter-pass: `run_tb_2d_rgb.sh` (no `--in11`).

Legacy grey flow: `rtl_img_tb.py` + `tb_2d.v` (uses `clip_to_8` and `(pixel-128)//4`).

---

# Evaluation Metrics

The evaluation configuration is controlled through `config.py`.

The following files share the same configuration settings:

- `new_hw_sim.py`
- `gen_test.py`
- `gen_test_all_keys.py`

---

# 1. Python Evaluation (`new_hw_sim.py`)

## Case Study

Single fractional key evaluation using:

- N = 32
- One fixed complex-valued test signal

### Metrics

### Real MSE

Mean squared error (MSE) of the 32-point real output.

### Imag MSE

Mean squared error (MSE) of the 32-point imaginary output.

### R+I MSE

Sum of:

- Real MSE
- Imag MSE

Complex MSE is implemented as:

MSE_complex = MSE_real + MSE_imag

### NMSE

Normalized mean squared error:

NMSE = (Real MSE + Imag MSE) / mean(|reference output|²)

where the reference output is the floating-point theoretical result after hardware gain scaling.

### Worst Error

Maximum single-point squared error among:

- all 32 real output samples
- all 32 imaginary output samples

This metric is NOT averaged.

---

## Error Sweep

Evaluation across:

- Keys from -128 to +127
- 10 random complex-valued input signals per key
- Signal length N = 32

### Overall MSE

Average complex MSE over:

- all keys
- all random test samples

where:

Complex MSE = Real MSE + Imag MSE

### Overall NMSE

Average NMSE over:

- all keys
- all random test samples

### Worst-case MSE

For each key:

1. Average Real MSE over the 10 random samples
2. Average Imag MSE over the 10 random samples
3. Compute:

Key MSE = Mean Real MSE + Mean Imag MSE

Worst-case MSE is the maximum Key MSE among all 256 keys.

---

# 2. RTL Testbench Evaluation (`tb`)

## Case Study

Single-key evaluation using:

- N = 32

### Metrics

### Real Channel MSE

Mean squared error of the 32-point real output channel.

### Imag Channel MSE

Mean squared error of the 32-point imaginary output channel.

### Total MSE

Sum of:

- Real Channel MSE
- Imag Channel MSE

---

# 3. Full-Key RTL Evaluation (`tb_all_key`)

## Full Sweep

Evaluation across:

- 256 keys
- Total of 8192 output points

### Metrics

### Real Channel MSE

Mean squared error of all 8192 real output samples.

### Imag Channel MSE

Mean squared error of all 8192 imaginary output samples.

### Total MSE

Sum of:

- Real Channel MSE
- Imag Channel MSE
