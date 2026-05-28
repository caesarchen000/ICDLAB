#!/usr/bin/env python3
"""
2D image FrFT — 32x32 blocks using new_hw_sim.hw_dfrft_pipeline (one row or column at a time).

Flow per 32x32 block:
  1. Greyscale image -> HW pack: (pixel-128)//4 in real byte, imag=0
  2. ENCRYPT key=64:
       1D: each ROW (32 pixels) -> hw_dfrft_pipeline -> 32 (real,imag) words -> enc_1d
       2D: each COLUMN of enc_1d -> pipeline again -> enc_2d (final ciphertext)
  3. DECRYPT key=-64 (reverse order of encrypt):
       1D: each COLUMN of enc_2d -> dec_1d
       2D: each ROW of dec_1d -> dec_2d (final; map bytes back to pixels)

Prereq: python3 new_hw_sim.py   # creates V_q.txt

Usage:
  python3 hw_sim_2d.py image.png
  python3 hw_sim_2d.py image.png --32
  python3 hw_sim_2d.py cross
  python3 hw_sim_2d.py image.png --rtl-dec   # decrypt row then col (tb_2d.v order)

Outputs:
  image_input.png, image_input_hw.png
  image_encrypted_1d.png, image_encrypted_2d.png
  image_decrypted_1d.png, image_decrypted_2d.png, image_decrypted_2d_restore.png
  hw_2d_one_image.png
"""
import os
import sys
import time
import numpy as np
from PIL import Image
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from tqdm import tqdm

from config import N

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

KEY_ENC = 64
KEY_DEC = -64
DEFAULT_MAX_DIM = 256


def clip_to_8(val_11):
    v = int(val_11)
    rounded = (v + 4) >> 3
    if rounded > 127:
        return 127
    if rounded < -128:
        return -128
    return rounded


def parse_hex8(hex_str):
    v = int(hex_str, 16)
    if v >= 128:
        v -= 256
    return v


def normalize_to_255(arr):
    arr_min, arr_max = arr.min(), arr.max()
    if arr_max > arr_min:
        return ((arr - arr_min) / (arr_max - arr_min)) * 255.0
    return arr


def rmse(a, b):
    return float(np.sqrt(np.mean((a - b) ** 2)))


def _open_gray(path):
    im = Image.open(path)
    if im.mode in ("RGBA", "LA"):
        bg = Image.new("RGB", im.size, (0, 0, 0))
        bg.paste(im, mask=im.split()[-1])
        im = bg
    return im.convert("L")


def load_png_full(path, max_dim=None, stretch=True):
    im = _open_gray(path)
    w, h = im.size
    if max_dim and max(w, h) > max_dim:
        scale = max_dim / float(max(w, h))
        w = int(round(w * scale))
        h = int(round(h * scale))
        im = im.resize((w, h), Image.LANCZOS)
    g = np.array(list(im.getdata()), dtype=np.float64).reshape(h, w)
    if stretch:
        lo, hi = g.min(), g.max()
        if hi > lo:
            g = (g - lo) / (hi - lo) * 255.0
    return g


def load_png_32(path, stretch=True):
    im = _open_gray(path)
    im = im.resize((32, 32), Image.LANCZOS)
    g = np.array(list(im.getdata()), dtype=np.float64).reshape(32, 32)
    if stretch:
        lo, hi = g.min(), g.max()
        if hi > lo:
            g = (g - lo) / (hi - lo) * 255.0
    return g


def pad_to_32(gray):
    h, w = gray.shape
    hp = ((h + 31) // 32) * 32
    wp = ((w + 31) // 32) * 32
    out = np.full((hp, wp), 128.0, dtype=np.float64)
    out[:h, :w] = gray
    return out, h, w


def save_gray_png(gray, path, upscale=1):
    u8 = np.clip(np.round(gray), 0, 255).astype(np.uint8)
    im = Image.fromarray(u8, mode="L")
    if upscale > 1:
        h, w = u8.shape
        im = im.resize((w * upscale, h * upscale), Image.NEAREST)
    im.save(path)


def upscale_to_size(gray, out_w, out_h):
    im = Image.fromarray(
        np.clip(np.round(gray), 0, 255).astype(np.uint8), mode="L"
    )
    return np.array(
        list(im.resize((out_w, out_h), Image.LANCZOS).getdata()),
        dtype=np.float64,
    ).reshape(out_h, out_w)


def make_cross_image():
    img = np.zeros((32, 32), dtype=np.int32)
    img[12:20, :] = 255
    img[:, 12:20] = 255
    return img


def gray_to_mem_in(img_gray):
    """32x32 grey -> HW words: imag=0, real=(pixel-128)//4."""
    h, w = img_gray.shape
    mem = np.zeros((h, w), dtype=np.uint16)
    for r in range(h):
        for c in range(w):
            scaled = int((int(img_gray[r, c]) - 128) // 4)
            scaled = max(-128, min(127, scaled))
            mem[r, c] = (0 << 8) | (scaled & 0xFF)
    return mem


def mem_word_to_r_i(word):
    imag = np.int8((int(word) >> 8) & 0xFF)
    real = np.int8(int(word) & 0xFF)
    return int(real), int(imag)


def mem_in_to_gray(mem):
    """Bytes -> pixel grey: real*4+128."""
    h, w = mem.shape
    gray = np.zeros((h, w), dtype=np.float64)
    for r in range(h):
        for c in range(w):
            real, _ = mem_word_to_r_i(mem[r, c])
            gray[r, c] = np.clip(real * 4 + 128, 0, 255)
    return gray


def process_1d_line(hw_dfrft_pipeline, mem_in, mem_out, key, stride_in, offset, stride_out):
    """
    One call to new_hw_sim: 32 (real,imag) in -> pipeline -> clip_to_8 -> 32 words out.
    Used for one ROW (stride 1) or one COLUMN (stride 32).
    """
    x_real = np.zeros(N, dtype=np.int64)
    x_imag = np.zeros(N, dtype=np.int64)
    for k in range(N):
        idx = offset + k * stride_in
        r, i = mem_word_to_r_i(mem_in.flat[idx])
        x_real[k] = r
        x_imag[k] = i
    out_r, out_i = hw_dfrft_pipeline(x_real, x_imag, key)
    for k in range(N):
        idx = offset + k * stride_out
        r8 = clip_to_8(int(out_r[k]))
        i8 = clip_to_8(int(out_i[k]))
        mem_out.flat[idx] = ((i8 & 0xFF) << 8) | (r8 & 0xFF)


def run_all_rows(mem_in, mem_out, key, hw_dfrft_pipeline):
    """1D encrypt/decrypt: 32 rows, each row is 32 pixels through hw_dfrft_pipeline."""
    for r in range(32):
        process_1d_line(hw_dfrft_pipeline, mem_in, mem_out, key, 1, r * 32, 1)


def run_all_columns(mem_in, mem_out, key, hw_dfrft_pipeline):
    """2D step: 32 columns, each column is 32 (real,imag) words through pipeline."""
    for c in range(32):
        process_1d_line(hw_dfrft_pipeline, mem_in, mem_out, key, 32, c, 32)


def encrypt_decrypt_block_stages(mem_in, key_enc, key_dec, hw_dfrft_pipeline, decrypt_col_first=True):
    """
    User / inverse-order decrypt (default):
      encrypt: rows (1D) -> columns (2D)
      decrypt: columns (1D) -> rows (2D)

    decrypt_col_first=False matches tb_2d.v (decrypt rows then columns).
    """
    enc_1d = np.zeros((32, 32), dtype=np.uint16)
    run_all_rows(mem_in, enc_1d, key_enc, hw_dfrft_pipeline)

    enc_2d = np.zeros((32, 32), dtype=np.uint16)
    run_all_columns(enc_1d, enc_2d, key_enc, hw_dfrft_pipeline)

    dec_1d = np.zeros((32, 32), dtype=np.uint16)
    dec_2d = np.zeros((32, 32), dtype=np.uint16)
    if decrypt_col_first:
        run_all_columns(enc_2d, dec_1d, key_dec, hw_dfrft_pipeline)
        run_all_rows(dec_1d, dec_2d, key_dec, hw_dfrft_pipeline)
    else:
        run_all_rows(enc_2d, dec_1d, key_dec, hw_dfrft_pipeline)
        run_all_columns(dec_1d, dec_2d, key_dec, hw_dfrft_pipeline)

    return enc_1d, enc_2d, dec_1d, dec_2d


def block_enc_vis(mem):
    mag = np.zeros((32, 32), dtype=np.float64)
    for r in range(32):
        for c in range(32):
            real, imag = mem_word_to_r_i(mem[r, c])
            mag[r, c] = np.sqrt(float(real * real + imag * imag))
    return normalize_to_255(mag)


def block_dec_vis(mem):
    raw = np.zeros((32, 32), dtype=np.float64)
    for r in range(32):
        for c in range(32):
            real, _ = mem_word_to_r_i(mem[r, c])
            raw[r, c] = real
    return normalize_to_255(raw)


def block_dec_restore(mem):
    return mem_in_to_gray(mem)


def encrypt_decrypt_tiled(gray_padded, hw_dfrft_pipeline, decrypt_col_first=True):
    H, W = gray_padded.shape
    nbr, nbc = H // 32, W // 32
    enc_1d_vis = np.zeros((H, W), dtype=np.float64)
    enc_2d_vis = np.zeros((H, W), dtype=np.float64)
    dec_1d_vis = np.zeros((H, W), dtype=np.float64)
    dec_2d_vis = np.zeros((H, W), dtype=np.float64)
    dec_2d_restore = np.zeros((H, W), dtype=np.float64)
    hw_in = np.zeros((H, W), dtype=np.float64)

    for br, bc in tqdm([(br, bc) for br in range(nbr) for bc in range(nbc)], desc="32x32 blocks"):
        rs, cs = br * 32, bc * 32
        block = gray_padded[rs : rs + 32, cs : cs + 32]
        mem_in = gray_to_mem_in(block)
        hw_in[rs : rs + 32, cs : cs + 32] = mem_in_to_gray(mem_in)
        e1, e2, d1, d2 = encrypt_decrypt_block_stages(
            mem_in, KEY_ENC, KEY_DEC, hw_dfrft_pipeline, decrypt_col_first
        )
        enc_1d_vis[rs : rs + 32, cs : cs + 32] = block_enc_vis(e1)
        enc_2d_vis[rs : rs + 32, cs : cs + 32] = block_enc_vis(e2)
        dec_1d_vis[rs : rs + 32, cs : cs + 32] = block_dec_vis(d1)
        dec_2d_vis[rs : rs + 32, cs : cs + 32] = block_dec_vis(d2)
        dec_2d_restore[rs : rs + 32, cs : cs + 32] = block_dec_restore(d2)

    return enc_1d_vis, enc_2d_vis, dec_1d_vis, dec_2d_vis, dec_2d_restore, hw_in


def plot_pipeline_stages(
    orig, hw_in, enc_1d, enc_2d, dec_1d, dec_2d, dec_restore, rmse_orig, rmse_hw, out_path
):
    h, w = orig.shape
    fig, axes = plt.subplots(2, 3, figsize=(15, 9))
    panels = [
        (axes[0, 0], orig, "gray", "Input (greyscale)"),
        (axes[0, 1], enc_1d, "turbo", f"Encrypt 1D (rows, key={KEY_ENC})"),
        (axes[0, 2], enc_2d, "turbo", f"Encrypt 2D (+cols, key={KEY_ENC})"),
        (axes[1, 0], hw_in, "gray", "HW packed input"),
        (axes[1, 1], dec_1d, "gray", f"Decrypt 1D (cols, key={KEY_DEC})"),
        (axes[1, 2], dec_restore, "gray", f"Decrypt 2D (+rows restore)"),
    ]
    for ax, img, cmap, title in panels:
        ax.imshow(img, cmap=cmap, vmin=0, vmax=255)
        ax.set_title(title)
        ax.axis("off")
    fig.suptitle(
        f"MSE vs original: {rmse_orig:.2f}   |   MSE vs HW input: {rmse_hw:.2f}  (0=perfect)",
        y=1.02,
    )
    plt.tight_layout()
    plt.savefig(out_path, dpi=120, bbox_inches="tight")
    plt.close()


def parse_args(argv):
    max_dim = DEFAULT_MAX_DIM
    force_32 = False
    use_cross = False
    rtl_dec = False
    png = None
    args = [a for a in argv[1:] if a]
    i = 0
    while i < len(args):
        if args[i] == "cross":
            use_cross = True
        elif args[i] == "--32":
            force_32 = True
        elif args[i] == "--rtl-dec":
            rtl_dec = True
        elif args[i] == "--max" and i + 1 < len(args):
            max_dim = int(args[i + 1])
            i += 1
        elif not args[i].startswith("-") and png is None:
            png = args[i]
        i += 1
    if png and not os.path.isabs(png):
        png = os.path.join(_SCRIPT_DIR, png)
    return png, use_cross, force_32, max_dim, rtl_dec


def main():
    png_path, use_cross, force_32, max_dim, rtl_dec = parse_args(sys.argv)

    vq_path = os.path.join(_SCRIPT_DIR, "V_q.txt")
    if not os.path.isfile(vq_path):
        print("Missing V_q.txt — run: python3 new_hw_sim.py")
        sys.exit(1)

    import new_hw_sim as nhs

    nhs.V_q = np.loadtxt(vq_path, dtype=np.int64)
    from new_hw_sim import hw_dfrft_pipeline

    decrypt_col_first = not rtl_dec
    print("Pipeline:")
    print("  Encrypt:  all ROWS (1D) -> all COLUMNS (2D), key=64")
    if decrypt_col_first:
        print("  Decrypt:  all COLUMNS (1D) -> all ROWS (2D), key=-64  [inverse order]")
    else:
        print("  Decrypt:  all ROWS -> all COLUMNS, key=-64  [tb_2d.v order, --rtl-dec]")

    if use_cross:
        orig = make_cross_image().astype(np.float64)
        crop_h, crop_w = 32, 32
        print("Source: built-in cross 32x32")
    else:
        if not png_path:
            png_path = os.path.join(_SCRIPT_DIR, "image.png")
        if not os.path.isfile(png_path):
            print("Need image.png or: python3 hw_sim_2d.py your.png")
            sys.exit(1)
        im0 = Image.open(png_path)
        print(f"Source: {png_path}  ({im0.size[0]}x{im0.size[1]})")
        if force_32:
            orig = load_png_32(png_path)
            crop_h, crop_w = 32, 32
            print("Mode: single 32x32 block")
        else:
            orig = load_png_full(png_path, max_dim=max_dim)
            crop_h, crop_w = orig.shape
            print(f"Mode: tiled blocks, canvas {crop_w}x{crop_h} (max side {max_dim})")

    gray_pad, crop_h, crop_w = pad_to_32(orig)
    nblk = (gray_pad.shape[0] // 32) * (gray_pad.shape[1] // 32)
    print(f"Blocks: {nblk}")

    t0 = time.time()
    enc_1d, enc_2d, dec_1d, dec_2d, dec_restore, hw_in = encrypt_decrypt_tiled(
        gray_pad, hw_dfrft_pipeline, decrypt_col_first=decrypt_col_first
    )
    print(f"Done in {time.time() - t0:.1f} s")

    orig_crop = gray_pad[:crop_h, :crop_w]
    hw_crop = hw_in[:crop_h, :crop_w]
    dec_rest_crop = dec_restore[:crop_h, :crop_w]

    rmse_orig = rmse(orig_crop, dec_rest_crop)
    rmse_hw = rmse(hw_crop, dec_rest_crop)

    print("")
    print("=== MSE after full decrypt (pixel = real*4+128) ===")
    print(f"  vs original greyscale image: {rmse_orig:.4f}")
    print(f"  vs HW packed input:          {rmse_hw:.4f}  (0 = perfect restore of packed data)")

    save_gray_png(orig_crop, os.path.join(_SCRIPT_DIR, "image_input.png"))
    save_gray_png(hw_crop, os.path.join(_SCRIPT_DIR, "image_input_hw.png"))
    save_gray_png(enc_1d[:crop_h, :crop_w], os.path.join(_SCRIPT_DIR, "image_encrypted_1d.png"))
    save_gray_png(enc_2d[:crop_h, :crop_w], os.path.join(_SCRIPT_DIR, "image_encrypted_2d.png"))
    save_gray_png(dec_1d[:crop_h, :crop_w], os.path.join(_SCRIPT_DIR, "image_decrypted_1d.png"))
    save_gray_png(dec_2d[:crop_h, :crop_w], os.path.join(_SCRIPT_DIR, "image_decrypted_2d.png"))
    save_gray_png(dec_rest_crop, os.path.join(_SCRIPT_DIR, "image_decrypted_2d_restore.png"))
    save_gray_png(enc_2d[:crop_h, :crop_w], os.path.join(_SCRIPT_DIR, "image_encrypted.png"))
    save_gray_png(dec_rest_crop, os.path.join(_SCRIPT_DIR, "image_decrypted.png"))

    if not use_cross and not force_32:
        im0 = Image.open(png_path)
        ow, oh = im0.size
        if (crop_w, crop_h) != (ow, oh):
            save_gray_png(
                upscale_to_size(dec_rest_crop, ow, oh),
                os.path.join(_SCRIPT_DIR, "image_decrypted_fullsize.png"),
            )

    plot_pipeline_stages(
        orig_crop,
        hw_crop,
        enc_1d[:crop_h, :crop_w],
        enc_2d[:crop_h, :crop_w],
        dec_1d[:crop_h, :crop_w],
        dec_2d[:crop_h, :crop_w],
        dec_rest_crop,
        rmse_orig,
        rmse_hw,
        os.path.join(_SCRIPT_DIR, "hw_2d_one_image.png"),
    )
    print("Saved PNGs + hw_2d_one_image.png")


if __name__ == "__main__":
    main()
