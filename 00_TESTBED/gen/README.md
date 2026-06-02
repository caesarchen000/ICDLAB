# RTL RGB image flow (11-bit, matches CHIP)https://github.com/caesarchen000/ICDLAB/tree/chip_new_v2

CHIP: `i_data[21:0] = {imag[10:0], real[10:0]}`, `o_data[10:0]`, saturate **11-bit** between row/col passes.

`config.py`: `INPUT_PORT = 11`, `OUTPUT_PORT = 11` (same as `new_hw_sim.py` and `tb_2d_rgb_11.v`).

## Main flow (11-bit)

```bash
cd 00_TESTBED/gen
python3 new_hw_sim.py --max 320 --fixed-key
python3 rtl_rgb_flow.py split
python3 rtl_rgb_flow.py golden          # optional, slow — reference for check
cd ../../01_RTL
bash run_tb_2d_rgb_11.sh
cd ../00_TESTBED/gen
python3 rtl_rgb_flow.py check           # optional
python3 rtl_rgb_flow.py merge --enc-preview
python3 rtl_rgb_flow.py show
```

| Step | Output |
|------|--------|
| `new_hw_sim.py` | `sim_image_resized.png`, `sim_image_*.png` |
| `split` | `pattern/img_r.txt`, `img_g.txt`, `img_b.txt` |
| `run_tb_2d_rgb_11.sh` | `pattern/r_enc1d_11.txt` … `r_dec2d_11.txt` |
| `merge` | `rtl_rgb_decrypted_11.png`, `rtl_rgb_encrypted_2d_11.png` |
| `show` | `rtl_rgb_pipeline_11.png` |

Key **40** / **-40**; decrypt: cols then rows.

`golden` / `check` default to 11-bit paths (no `--in11` flag needed). Use `--in8` for legacy 8-bit.

## Legacy 8-bit (`tb_2d_rgb.v`)

```bash
python3 rtl_rgb_flow.py --in8 split
python3 rtl_rgb_flow.py --in8 golden
cd ../../01_RTL && bash run_tb_2d_rgb.sh
cd ../00_TESTBED/gen
python3 rtl_rgb_flow.py --in8 check
python3 rtl_rgb_flow.py --in8 merge --enc-preview
```

## Post-APR gate (`05_APR/CHIP.v`)

```bash
python3 rtl_rgb_flow.py split
cd ../../05_APR && bash run_tb_2d_rgb_11.sh
cd ../00_TESTBED/gen && python3 rtl_rgb_flow.py merge --enc-preview
```

(APR dumps: `*_11_apr.txt` if using `+define+APR_TAG` in `05_APR/run_tb_2d_rgb_11.sh`.)


full 11bit
cd ~/chip_v2/00_TESTBED/gen
python3 new_hw_sim.py --max 320 --fixed-key
python3 rtl_rgb_flow.py split

# optional (slow): python3 rtl_rgb_flow.py golden

cd ../../01_RTL
bash run_tb_2d_rgb_11.sh

cd ../00_TESTBED/gen
python3 rtl_rgb_flow.py merge --enc-preview
python3 rtl_rgb_flow.py show

# optional after golden finishes:
# python3 rtl_rgb_flow.py check

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
