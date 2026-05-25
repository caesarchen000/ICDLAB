#!/usr/bin/env python3
"""
RTL 2D image testbench flow (tb_2d.v):
  1. export  — sim_image_resized.png -> pattern/img_in.txt (+ golden enc/dec)
  2. check   — compare pattern/img_dec.txt vs Python golden
  3. show    — plot pattern/img_*.txt

Uses same pipeline as tb_2d / hw_sim_2d:
  pack (pixel-128)//4, clip_to_8, key=40, encrypt rows->cols, decrypt cols->rows

Prereq: python3 new_hw_sim.py

Run RTL (from 01_RTL):
  vcs ../00_TESTBED/testbench/tb_2d.v -f rtl.f -full64 -R +v2k -debug_access+all

Example:
  cd 00_TESTBED/gen
  python3 rtl_img_tb.py export
  cd ../../01_RTL && vcs ../00_TESTBED/testbench/tb_2d.v -f rtl.f -full64 -R +v2k -debug_access+all
  cd ../00_TESTBED/gen && python3 rtl_img_tb.py check
  python3 rtl_img_tb.py show
"""
from __future__ import print_function

import os
import sys
import argparse
import numpy as np
from PIL import Image
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
_PATTERN_DIR = os.path.join(_SCRIPT_DIR, "..", "pattern")

# tb_2d.v localparam KEY_ENC = 40
RTL_KEY_ENC = 40
RTL_KEY_DEC = -40
DEFAULT_MAX_DIM = 320
DEFAULT_IMAGE = "sim_image_resized.png"


def word_to_hex_lines(mem_u16):
    """32x32 uint16 words -> list of 'II RR' lines (imag real)."""
    lines = []
    for word in mem_u16.flat:
        imag = (int(word) >> 8) & 0xFF
        real = int(word) & 0xFF
        lines.append("{:02X} {:02X}".format(imag, real))
    return lines


def write_lines(path, lines):
    with open(path, "w") as f:
        for ln in lines:
            f.write(ln + "\n")


def read_hex_lines(path):
    out = []
    with open(path, "r") as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 2:
                out.append((parts[0], parts[1]))
    return out


def parse_hex8(hex_str):
    v = int(hex_str, 16)
    if v >= 128:
        v -= 256
    return v


def lines_to_grey(lines):
    grey = np.zeros(len(lines), dtype=np.float64)
    for i, (im, re) in enumerate(lines):
        real = parse_hex8(re)
        grey[i] = np.clip(real * 4 + 128, 0, 255)
    return grey


def setup_hw_sim():
    vq = os.path.join(_SCRIPT_DIR, "V_q.txt")
    if not os.path.isfile(vq):
        print("Missing V_q.txt — run: python3 new_hw_sim.py")
        sys.exit(1)
    import new_hw_sim as nhs
    import hw_sim_2d as h2d

    nhs.V_q = np.loadtxt(vq, dtype=np.int64)
    h2d.KEY_ENC = RTL_KEY_ENC
    h2d.KEY_DEC = RTL_KEY_DEC
    from new_hw_sim import hw_dfrft_pipeline

    return h2d, hw_dfrft_pipeline


def load_canvas_png(png_path):
    """Load sim canvas as-is (no resize / no histogram stretch). RGB -> greyscale."""
    im = Image.open(png_path)
    if im.mode in ("RGBA", "LA"):
        bg = Image.new("RGB", im.size, (0, 0, 0))
        bg.paste(im, mask=im.split()[-1])
        im = bg
    if im.mode != "L":
        im = im.convert("L")
    w, h = im.size
    gray = np.array(list(im.getdata()), dtype=np.float64).reshape(h, w)
    return gray, h, w


def load_image(png_path, max_dim, force_32, use_canvas=False):
    h2d, hw_dfrft_pipeline = setup_hw_sim()
    if not os.path.isabs(png_path):
        png_path = os.path.join(_SCRIPT_DIR, png_path)
    if use_canvas or os.path.basename(png_path) == DEFAULT_IMAGE:
        gray, crop_h, crop_w = load_canvas_png(png_path)
    elif force_32:
        gray = h2d.load_png_32(png_path)
        crop_h, crop_w = 32, 32
    else:
        gray = h2d.load_png_full(png_path, max_dim=max_dim)
        crop_h, crop_w = gray.shape
    gray_pad, crop_h, crop_w = h2d.pad_to_32(gray)
    return gray, gray_pad, crop_h, crop_w, h2d, hw_dfrft_pipeline


def cmd_export(args):
    png = args.image
    if not os.path.isfile(os.path.join(_SCRIPT_DIR, png) if not os.path.isabs(png) else png):
        print("Missing image:", png)
        sys.exit(1)

    gray, gray_pad, crop_h, crop_w, h2d, hw_dfrft_pipeline = load_image(
        png, args.max_dim, args.force_32, use_canvas=args.canvas
    )

    H, W = gray_pad.shape
    mem_in_lines = []
    mem_enc_lines = []
    mem_dec_lines = []

    nbr, nbc = H // 32, W // 32
    for br in range(nbr):
        for bc in range(nbc):
            block = gray_pad[br * 32 : (br + 1) * 32, bc * 32 : (bc + 1) * 32]
            mem_in = h2d.gray_to_mem_in(block)
            _, enc_2d, _, dec_2d = h2d.encrypt_decrypt_block_stages(
                mem_in, RTL_KEY_ENC, RTL_KEY_DEC, hw_dfrft_pipeline, decrypt_col_first=True
            )
            mem_in_lines.extend(word_to_hex_lines(mem_in))
            mem_enc_lines.extend(word_to_hex_lines(enc_2d))
            mem_dec_lines.extend(word_to_hex_lines(dec_2d))

    write_lines(os.path.join(_PATTERN_DIR, "img_in.txt"), mem_in_lines)
    write_lines(os.path.join(_PATTERN_DIR, "img_golden_enc.txt"), mem_enc_lines)
    write_lines(os.path.join(_PATTERN_DIR, "img_golden_dec.txt"), mem_dec_lines)
    with open(os.path.join(_PATTERN_DIR, "img_meta.txt"), "w") as f:
        f.write("crop_h={}\n".format(crop_h))
        f.write("crop_w={}\n".format(crop_w))
        f.write("canvas_h={}\n".format(H))
        f.write("canvas_w={}\n".format(W))
        f.write("key_enc={}\n".format(RTL_KEY_ENC))
        f.write("pixels={}\n".format(len(mem_in_lines)))
        f.write("blocks={}\n".format(nbr * nbc))

    print("Exported RTL patterns (key={}, decrypt=col then row)".format(RTL_KEY_ENC))
    print("  source: {}".format(png if os.path.isabs(png) else os.path.join(_SCRIPT_DIR, png)))
    print("  pixels={}  blocks={}  canvas={}x{}  crop={}x{}".format(
        len(mem_in_lines), nbr * nbc, W, H, crop_w, crop_h))
    print("  {}/img_in.txt".format(_PATTERN_DIR))
    print("  {}/img_golden_dec.txt".format(_PATTERN_DIR))


def cmd_check(args):
    dec_path = os.path.join(_PATTERN_DIR, "img_dec.txt")
    gold_path = os.path.join(_PATTERN_DIR, "img_golden_dec.txt")
    in_path = os.path.join(_PATTERN_DIR, "img_in.txt")

    if not os.path.isfile(dec_path):
        print("Missing {} - run tb_2d.v simulation first".format(dec_path))
        sys.exit(1)
    if not os.path.isfile(gold_path):
        print("Missing {} - run: python3 rtl_img_tb.py export".format(gold_path))
        sys.exit(1)

    hw_dec = read_hex_lines(dec_path)
    gold_dec = read_hex_lines(gold_path)
    mem_in = read_hex_lines(in_path)

    if len(hw_dec) != len(gold_dec):
        print("Length mismatch: RTL {} vs golden {}".format(len(hw_dec), len(gold_dec)))
        sys.exit(1)

    mism = sum(1 for a, b in zip(hw_dec, gold_dec) if a != b)
    print("Word compare (imag real hex): {}/{} mismatches".format(mism, len(hw_dec)))
    if mism == 0:
        print("PASS - RTL img_dec.txt matches Python golden bit-for-bit")
    else:
        print("FAIL - first mismatches:")
        shown = 0
        for i, (a, b) in enumerate(zip(hw_dec, gold_dec)):
            if a != b:
                print("  [{}] RTL {}  gold {}".format(i, a, b))
                shown += 1
                if shown >= 5:
                    break

    grey_in = lines_to_grey(mem_in)
    grey_hw = lines_to_grey(hw_dec)
    grey_gold = lines_to_grey(gold_dec)

    def rmse(a, b):
        return float(np.sqrt(np.mean((a - b) ** 2)))

    print("")
    print("Restored grey RMSE (pixel = real*4+128):")
    print("  RTL vs packed input:  {:.4f}".format(rmse(grey_in, grey_hw)))
    print("  Gold vs packed input: {:.4f}".format(rmse(grey_in, grey_gold)))
    print("  RTL vs golden:        {:.4f}".format(rmse(grey_gold, grey_hw)))

    sys.exit(0 if mism == 0 else 1)


def cmd_show(args):
    in_path = os.path.join(_PATTERN_DIR, "img_in.txt")
    enc_path = os.path.join(_PATTERN_DIR, "img_enc.txt")
    dec_path = os.path.join(_PATTERN_DIR, "img_dec.txt")
    for p in (in_path, enc_path, dec_path):
        if not os.path.isfile(p):
            print("Missing", p)
            sys.exit(1)

    mem_in = read_hex_lines(in_path)
    mem_enc = read_hex_lines(enc_path)
    mem_dec = read_hex_lines(dec_path)
    n = len(mem_in)
    side = int(np.sqrt(n))
    if side * side != n:
        print("Not square pixel count:", n)
        sys.exit(1)

    orig = lines_to_grey(mem_in).reshape(side, side)
    dec = lines_to_grey(mem_dec).reshape(side, side)
    mag = np.zeros(n, dtype=np.float64)
    for i, (im, re) in enumerate(mem_enc):
        r, j = parse_hex8(re), parse_hex8(im)
        mag[i] = np.sqrt(float(r * r + j * j))
    enc = mag.reshape(side, side)
    lo, hi = enc.min(), enc.max()
    if hi > lo:
        enc = (enc - lo) / (hi - lo) * 255.0

    fig, ax = plt.subplots(1, 3, figsize=(15, 5))
    ax[0].imshow(orig, cmap="gray", vmin=0, vmax=255)
    ax[0].set_title("Input (HW packed)")
    ax[1].imshow(enc, cmap="turbo")
    ax[1].set_title("Encrypted (key={})".format(RTL_KEY_ENC))
    ax[2].imshow(dec, cmap="gray", vmin=0, vmax=255)
    ax[2].set_title("Decrypted (key={})".format(RTL_KEY_DEC))
    for a in ax:
        a.axis("off")
    out = os.path.join(_SCRIPT_DIR, "rtl_hw_2d_check.png")
    plt.tight_layout()
    plt.savefig(out, dpi=120, bbox_inches="tight")
    plt.close()
    print("Saved", out)


def main():
    ap = argparse.ArgumentParser(description="RTL tb_2d image export / check / show")
    ap.add_argument("command", choices=["export", "check", "show"])
    ap.add_argument(
        "image",
        nargs="?",
        default=DEFAULT_IMAGE,
        help="PNG for export (default: sim_image_resized.png)",
    )
    ap.add_argument(
        "--canvas",
        action="store_true",
        help="load image at native size, no --max resize or stretch",
    )
    ap.add_argument("--max", dest="max_dim", type=int, default=DEFAULT_MAX_DIM)
    ap.add_argument("--32", dest="force_32", action="store_true")
    args = ap.parse_args()

    if args.command == "export":
        cmd_export(args)
    elif args.command == "check":
        cmd_check(args)
    else:
        cmd_show(args)


if __name__ == "__main__":
    main()
