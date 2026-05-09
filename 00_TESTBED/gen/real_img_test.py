import numpy as np
import matplotlib.pyplot as plt
from PIL import Image
import sys
import os

BLOCK_SIZE = 32

def to_hex8(val):
    v = int(max(-128, min(127, val)))
    return f"{(v & 0xFF):02X}"

def parse_hex8(hex_str):
    v = int(hex_str, 16)
    if v >= 128: v -= 256
    return v

def generate_blocks():
    # 讀取真實影像，轉灰階
    if os.path.exists("test.jpg"):
        img = Image.open("test.jpg").convert("L")
        # 為了模擬速度，將圖片 Resize 到 64x64 (共 4 個 Blocks)
        img = img.resize((64, 64))
        print("✅ 讀取 test.jpg 並調整為 640x640 像素。")
    else:
        # 找不到圖就產生漸層幾何圖案
        x = np.linspace(-3, 3, 64)
        y = np.linspace(-3, 3, 64)
        xx, yy = np.meshgrid(x, y)
        img_arr = np.sin(xx**2 + yy**2) * 127 + 128
        img = Image.fromarray(img_arr.astype(np.uint8))
        print("⚠️ 找不到 test.jpg，產生預設 64x64 幾何圖案。")

    img_arr = np.array(img, dtype=int)
    H, W = img_arr.shape
    
    # 寫入 Block 測資
    with open("../pattern/img_in.txt", "w") as f:
        for by in range(0, H, BLOCK_SIZE):
            for bx in range(0, W, BLOCK_SIZE):
                block = img_arr[by:by+BLOCK_SIZE, bx:bx+BLOCK_SIZE]
                for r in range(BLOCK_SIZE):
                    for c in range(BLOCK_SIZE):
                        # 去直流並縮放：移至 0 點，並除以 2 以保留更多細節
                        scaled_pixel = (block[r, c] - 128) // 2
                        f.write(f"00 {to_hex8(scaled_pixel)}\n")
                        
    print(f"✅ 成功切分 {H*W//1024} 個 Blocks，測資已生成！")
    return H, W

def reconstruct_blocks(filename, H, W, is_encrypted=False):
    img_out = np.zeros((H, W), dtype=float)
    try:
        with open(filename, "r") as f:
            lines = f.readlines()
            idx = 0
            for by in range(0, H, BLOCK_SIZE):
                for bx in range(0, W, BLOCK_SIZE):
                    for r in range(BLOCK_SIZE):
                        for c in range(BLOCK_SIZE):
                            if idx < len(lines):
                                parts = lines[idx].strip().split()
                                imag_val = parse_hex8(parts[0])
                                real_val = parse_hex8(parts[1])
                                if is_encrypted:
                                    img_out[by+r, bx+c] = np.sqrt(real_val**2 + imag_val**2)
                                else:
                                    img_out[by+r, bx+c] = real_val
                                idx += 1
        return img_out
    except FileNotFoundError:
        print(f"❌ 找不到 {filename}！")
        return None

def normalize_to_255(arr):
    arr_min, arr_max = arr.min(), arr.max()
    if arr_max > arr_min:
        return ((arr - arr_min) / (arr_max - arr_min)) * 255.0
    return arr

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "show":
        # 假設固定為 64x64
        H, W = 64, 64
        orig = reconstruct_blocks("../pattern/img_in.txt", H, W, False)
        # 把原始圖加回 128，乘回 2
        orig = (orig * 2) + 128
                
        enc = reconstruct_blocks("../pattern/img_enc.txt", H, W, True)
        dec = reconstruct_blocks("../pattern/img_dec.txt", H, W, False)
        
        if enc is not None and dec is not None:
            enc_vis = normalize_to_255(enc)
            dec_vis = normalize_to_255(dec)
            
            fig, ax = plt.subplots(1, 3, figsize=(15, 5))
            ax[0].imshow(orig, cmap='gray', vmin=0, vmax=255); ax[0].set_title("1. Original Image")
            ax[1].imshow(enc_vis, cmap='turbo'); ax[1].set_title("2. Hardware Encrypted")
            ax[2].imshow(dec_vis, cmap='gray', vmin=0, vmax=255);  ax[2].set_title("3. Hardware Decrypted")
            plt.tight_layout()
            plt.savefig('hw_real_image_encryption.png')
            print("✅ 成功繪製比對圖 hw_real_image_encryption.png！")
            plt.show()
    else:
        generate_blocks()