#!/usr/bin/env python3
"""
RGB RTL image encryption flow (8-bit in, 11-bit out, saturate between passes).

Step 1  split   : sim_image_resized.png -> pattern/img_r.txt, img_g.txt, img_b.txt
                  (one decimal 0..255 per line, row-major)

Step 2  RTL     : tb_2d_rgb.v per channel (+define+CH_R|CH_G|CH_B)
                  reads img_<ch>.txt, writes <ch>_enc1d/enc2d/dec1d/dec2d.txt
                  (hex imag real per pixel; pack input as pixel-128, imag=0)

Step 3  merge   : r/g/b *_dec2d.txt -> rtl_rgb_decrypted.png
                  optional enc previews from *_enc2d.txt

Step 4  golden / check : Python reference (INPUT_PORT=8, saturate like new_hw_sim)

Prereq: python3 new_hw_sim.py

RTL (from 01_RTL, run 3 times):
  vcs ../00_TESTBED/testbench/tb_2d_rgb.v -f rtl.f +define+CH_R -full64 -R +v2k
  vcs ../00_TESTBED/testbench/tb_2d_rgb.v -f rtl.f +define+CH_G -full64 -R +v2k
  vcs ../00_TESTBED/testbench/tb_2d_rgb.v -f rtl.f +define+CH_B -full64 -R +v2k
"""
from __future__ import print_function

import os
import sys
import argparse
import json
import numpy as np
from PIL import Image
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
_PATTERN_DIR = os.path.join(_SCRIPT_DIR, "..", "pattern")
_RTL_DIR = os.path.join(_SCRIPT_DIR, "..", "..", "01_RTL")

DEFAULT_IMAGE = "sim_image_resized.png"
CHANNELS = ("r", "g", "b")
KEY_ENC = 40
KEY_DEC = -40
INPUT_BITS_8 = 8
INPUT_BITS_11 = 11
N = 32


def stage_tag(in11):
    return "_11" if in11 else ""


def stage_path(ch, st, in11, golden=False):
    mid = "_golden_" if golden else "_"
    return os.path.join(_PATTERN_DIR, "{}{}{}{}.txt".format(ch, mid, st, stage_tag(in11)))


def parse_hex_signed(s, bits):
    mask = (1 << bits) - 1
    v = int(s, 16) & mask
    if v >= (1 << (bits - 1)):
        v -= 1 << bits
    return v


def to_hex_signed(val, bits):
    lo, hi = input_limits(bits)
    v = int(max(lo, min(hi, val)))
    mask = (1 << bits) - 1
    width = (bits + 3) // 4
    return ("{:0" + str(width) + "X}").format(v & mask)


def parse_hex8(s):
    return parse_hex_signed(s, 8)


def to_hex8(val):
    return to_hex_signed(val, 8)


def input_limits(bits):
    hi = (1 << (bits - 1)) - 1
    lo = -(1 << (bits - 1))
    return lo, hi


def saturate_val(val, bits):
    lo, hi = input_limits(bits)
    v = int(val)
    if v > hi:
        return hi
    if v < lo:
        return lo
    return v


def write_decimal_channel(path, plane):
    with open(path, "w") as f:
        for v in plane.astype(np.int32).flat:
            f.write("{}\n".format(int(v)))


def read_decimal_channel(path):
    vals = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if line:
                vals.append(int(line))
    return np.array(vals, dtype=np.int64)


def read_hex_mem(path):
    rows = []
    with open(path, "r") as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 2:
                rows.append((parts[0], parts[1]))
    return rows


def write_hex_mem(path, words):
    with open(path, "w") as f:
        for im, re in words:
            f.write("{} {}\n".format(im, re))


def words_to_real_plane(words, h, w, bits=8):
    out = np.zeros((h, w), dtype=np.float64)
    for idx, (im, re) in enumerate(words):
        r = parse_hex_signed(re, bits)
        out.flat[idx] = np.clip(r + 128, 0, 255)
    return out


def words_to_mag_plane(words, h, w, bits=8):
    out = np.zeros((h, w), dtype=np.float64)
    for idx, (im, re) in enumerate(words):
        r = parse_hex_signed(re, bits)
        j = parse_hex_signed(im, bits)
        out.flat[idx] = np.sqrt(float(r * r + j * j))
    return out


def normalize_vis(arr):
    lo, hi = arr.min(), arr.max()
    if hi > lo:
        return (arr - lo) / (hi - lo) * 255.0
    return arr


def load_rgb_canvas(path):
    path = path if os.path.isabs(path) else os.path.join(_SCRIPT_DIR, path)
    if not os.path.isfile(path):
        print("Missing:", path)
        sys.exit(1)
    im = Image.open(path).convert("RGB")
    arr = np.array(list(im.getdata()), dtype=np.float64).reshape(im.size[1], im.size[0], 3)
    return arr, im.size[1], im.size[0]


def setup_hw(bits):
    vq = os.path.join(_SCRIPT_DIR, "V_q.txt")
    if not os.path.isfile(vq):
        print("Missing V_q.txt - run: python3 new_hw_sim.py")
        sys.exit(1)
    import config
    import new_hw_sim as nhs

    old_port = config.INPUT_PORT
    config.INPUT_PORT = bits
    nhs.V_q = np.loadtxt(vq, dtype=np.int64)
    from new_hw_sim import hw_dfrft_pipeline, dfrft_pass_2d

    return config, hw_dfrft_pipeline, dfrft_pass_2d, old_port


def process_block(block, hw_dfrft_pipeline, dfrft_pass_2d, bits, key_enc=KEY_ENC, key_dec=KEY_DEC):
    lo, hi = input_limits()
    real0 = np.clip(np.round(block - 128), lo, hi).astype(np.int64)
    imag0 = np.zeros((N, N), dtype=np.int64)

    enc1_r, enc1_i = dfrft_pass_2d(real0, imag0, key_enc, "row", report_clips=False, stage="")
    enc2_r, enc2_i = dfrft_pass_2d(enc1_r, enc1_i, key_enc, "col", report_clips=False, stage="")
    dec1_r, dec1_i = dfrft_pass_2d(enc2_r, enc2_i, key_dec, "col", report_clips=False, stage="")
    dec2_r, dec2_i = dfrft_pass_2d(dec1_r, dec1_i, key_dec, "row", report_clips=False, stage="")
    return enc1_r, enc1_i, enc2_r, enc2_i, dec1_r, dec1_i, dec2_r, dec2_i


def ri_to_words(real, imag, bits):
    lines = []
    for r, i in zip(real.flat, imag.flat):
        lines.append((to_hex_signed(i, bits), to_hex_signed(r, bits)))
    return lines


def cmd_split(args):
    rgb, h, w = load_rgb_canvas(args.image)
    meta = {"h": h, "w": w, "channels": list(CHANNELS)}
    for ci, ch in enumerate(CHANNELS):
        p = os.path.join(_PATTERN_DIR, "img_{}.txt".format(ch))
        write_decimal_channel(p, rgb[:, :, ci])
        print("Wrote {} ({} values)".format(p, h * w))
    meta_path = os.path.join(_PATTERN_DIR, "rgb_meta.json")
    with open(meta_path, "w") as f:
        json.dump(meta, f, indent=2)
    print("Meta:", meta_path)


def golden_channel_plane(plane, hw_dfrft_pipeline, dfrft_pass_2d, bits):
    h, w = plane.shape
    hp = ((h + 31) // 32) * 32
    wp = ((w + 31) // 32) * 32
    pad = np.full((hp, wp), 128.0, dtype=np.float64)
    pad[:h, :w] = plane

    enc1_all, enc2_all, dec1_all, dec2_all = [], [], [], []
    for br in range(hp // N):
        for bc in range(wp // N):
            block = pad[br * N : (br + 1) * N, bc * N : (bc + 1) * N]
            e1r, e1i, e2r, e2i, d1r, d1i, d2r, d2i = process_block(
                block, hw_dfrft_pipeline, dfrft_pass_2d, bits
            )
            enc1_all.extend(ri_to_words(e1r, e1i, bits))
            enc2_all.extend(ri_to_words(e2r, e2i, bits))
            dec1_all.extend(ri_to_words(d1r, d1i, bits))
            dec2_all.extend(ri_to_words(d2r, d2i, bits))

    return enc1_all, enc2_all, dec1_all, dec2_all, hp, wp


def cmd_golden(args):
    bits = INPUT_BITS_11 if args.in11 else INPUT_BITS_8
    config, hw_dfrft_pipeline, dfrft_pass_2d, old_port = setup_hw(bits)
    print("Golden INPUT_PORT={}-bit saturate".format(bits))
    try:
        rgb, h, w = load_rgb_canvas(args.image)
        for ci, ch in enumerate(CHANNELS):
            print("Golden channel", ch)
            e1, e2, d1, d2, hp, wp = golden_channel_plane(
                rgb[:, :, ci], hw_dfrft_pipeline, dfrft_pass_2d, bits
            )
            write_hex_mem(stage_path(ch, "enc1d", args.in11, golden=True), e1)
            write_hex_mem(stage_path(ch, "enc2d", args.in11, golden=True), e2)
            write_hex_mem(stage_path(ch, "dec1d", args.in11, golden=True), d1)
            write_hex_mem(stage_path(ch, "dec2d", args.in11, golden=True), d2)
            print("  {} words  canvas {}x{}".format(len(e2), wp, hp))
    finally:
        config.INPUT_PORT = old_port


def cmd_check(args):
    stages = ("enc1d", "enc2d", "dec1d", "dec2d")
    ok_all = True
    for ch in CHANNELS:
        for st in stages:
            rtl_p = stage_path(ch, st, args.in11, golden=False)
            gold_p = stage_path(ch, st, args.in11, golden=True)
            if not os.path.isfile(rtl_p):
                print("Missing RTL:", rtl_p)
                ok_all = False
                continue
            if not os.path.isfile(gold_p):
                print("Missing golden - run: python3 rtl_rgb_flow.py golden")
                sys.exit(1)
            rtl = read_hex_mem(rtl_p)
            gold = read_hex_mem(gold_p)
            if len(rtl) != len(gold):
                print("FAIL {} {}: len {} vs {}".format(ch, st, len(rtl), len(gold)))
                ok_all = False
                continue
            mism = sum(1 for a, b in zip(rtl, gold) if a != b)
            status = "PASS" if mism == 0 else "FAIL"
            print("{} {} {}: {}/{} mismatches".format(status, ch, st, mism, len(rtl)))
            if mism:
                ok_all = False
    sys.exit(0 if ok_all else 1)


def cmd_merge(args):
    bits = INPUT_BITS_11 if args.in11 else INPUT_BITS_8
    meta_path = os.path.join(_PATTERN_DIR, "rgb_meta.json")
    if os.path.isfile(meta_path):
        with open(meta_path) as f:
            meta = json.load(f)
        h, w = meta["h"], meta["w"]
    else:
        n = len(read_hex_mem(stage_path("r", "dec2d", args.in11)))
        side = int(np.sqrt(n))
        h = w = side

    planes = []
    for ch in CHANNELS:
        p = stage_path(ch, "dec2d", args.in11)
        if not os.path.isfile(p):
            print("Missing", p)
            sys.exit(1)
        words = read_hex_mem(p)
        if len(words) < h * w:
            print("Too few pixels in", p)
            sys.exit(1)
        planes.append(words_to_real_plane(words, h, w, bits))

    rgb = np.stack(planes, axis=2)
    u8 = np.clip(np.round(rgb), 0, 255).astype(np.uint8)
    suffix = "_11" if args.in11 else ""
    out_dec = os.path.join(_SCRIPT_DIR, "rtl_rgb_decrypted{}.png".format(suffix))
    Image.fromarray(u8, mode="RGB").save(out_dec)
    print("Saved", out_dec)

    if args.enc_preview:
        enc_planes = []
        for ch in CHANNELS:
            p = stage_path(ch, "enc2d", args.in11)
            words = read_hex_mem(p)
            enc_planes.append(normalize_vis(words_to_mag_plane(words, h, w, bits)))
        enc_rgb = np.stack(enc_planes, axis=2)
        out_enc = os.path.join(_SCRIPT_DIR, "rtl_rgb_encrypted_2d{}.png".format(suffix))
        Image.fromarray(np.clip(enc_rgb, 0, 255).astype(np.uint8), mode="RGB").save(out_enc)
        print("Saved", out_enc)


def cmd_show(args):
    meta_path = os.path.join(_PATTERN_DIR, "rgb_meta.json")
    if os.path.isfile(meta_path):
        with open(meta_path) as f:
            meta = json.load(f)
        h, w = meta["h"], meta["w"]
    else:
        h = w = int(np.sqrt(len(read_decimal_channel(os.path.join(_PATTERN_DIR, "img_r.txt")))))

    fig, axes = plt.subplots(3, 5, figsize=(18, 10))
    bits = INPUT_BITS_11 if args.in11 else INPUT_BITS_8
    tag11 = stage_tag(args.in11)
    cols = [
        ("in", "img_{}.txt", "decimal"),
        ("enc1d", "{}_enc1d{}.txt", "hex"),
        ("enc2d", "{}_enc2d{}.txt", "hex"),
        ("dec1d", "{}_dec1d{}.txt", "hex"),
        ("dec2d", "{}_dec2d{}.txt", "hex"),
    ]
    for ri, ch in enumerate(CHANNELS):
        for ci, (label, tmpl, kind) in enumerate(cols):
            path = os.path.join(_PATTERN_DIR, tmpl.format(ch, tag11))
            if not os.path.isfile(path):
                axes[ri, ci].set_title("{} missing".format(label))
                axes[ri, ci].axis("off")
                continue
            if kind == "decimal":
                img = read_decimal_channel(path).reshape(h, w)
            elif label in ("enc2d", "enc1d"):
                img = normalize_vis(words_to_mag_plane(read_hex_mem(path), h, w, bits))
            else:
                img = words_to_real_plane(read_hex_mem(path), h, w, bits)
            axes[ri, ci].imshow(
                img, cmap="gray" if label in ("in", "dec1d", "dec2d") else "turbo", vmin=0, vmax=255
            )
            axes[ri, ci].set_title("{} {}".format(ch, label))
            axes[ri, ci].axis("off")
    out = os.path.join(_SCRIPT_DIR, "rtl_rgb_pipeline{}.png".format("_11" if args.in11 else ""))
    plt.tight_layout()
    plt.savefig(out, dpi=120, bbox_inches="tight")
    plt.close()
    print("Saved", out)


def main():
    ap = argparse.ArgumentParser(description="RGB RTL image encrypt/decrypt flow")
    ap.add_argument(
        "--in11",
        action="store_true",
        help="11-bit inter-pass paths (*_11.txt, rtl_rgb_decrypted_11.png)",
    )
    sub = ap.add_subparsers(dest="cmd")

    p_split = sub.add_parser("split", help="PNG -> img_r/g/b.txt (0-255 per line)")
    p_split.add_argument("image", nargs="?", default=DEFAULT_IMAGE)

    p_gold = sub.add_parser("golden", help="Python saturate reference (8- or 11-bit)")
    p_gold.add_argument("image", nargs="?", default=DEFAULT_IMAGE)

    sub.add_parser("check", help="compare RTL vs golden hex files")

    p_merge = sub.add_parser("merge", help="dec2d r/g/b -> RGB PNG")
    p_merge.add_argument("--enc-preview", action="store_true")

    sub.add_parser("show", help="grid plot of all stage files")

    args = ap.parse_args()
    if not args.cmd:
        ap.print_help()
        sys.exit(1)
    if args.cmd == "split":
        cmd_split(args)
    elif args.cmd == "golden":
        cmd_golden(args)
    elif args.cmd == "check":
        cmd_check(args)
    elif args.cmd == "merge":
        cmd_merge(args)
    elif args.cmd == "show":
        cmd_show(args)


if __name__ == "__main__":
    main()
