import numpy as np
import matplotlib.pyplot as plt
import sys

def to_hex8(val):
    v = int(max(-128, min(127, val)))
    return f"{(v & 0xFF):02X}"

def parse_hex8(hex_str):
    v = int(hex_str, 16)
    if v >= 128: v -= 256
    return v

def generate_image():
    # 產生白十字測試圖 (0~255)
    img = np.zeros((32, 32), dtype=int)
    img[12:20, :] = 255
    img[:, 12:20] = 255
    
    with open("../pattern/img_in.txt", "w") as f:
        for r in range(32):
            for c in range(32):
                # [修復核心] 減去 128 使其 Zero-Centered，再除以 4
                # 數值會完美落在 -32 ~ +31 之間，徹底消滅 DC 溢位！
                scaled_pixel = (img[r, c] - 128) // 4 
                f.write(f"00 {to_hex8(scaled_pixel)}\n")
    print("✅ 成功生成 Zero-Centered 安全縮放版測資: img_in.txt")

def read_hw_output(filename, is_encrypted=False):
    img_out = np.zeros((32, 32), dtype=float)
    try:
        with open(filename, "r") as f:
            lines = f.readlines()
            idx = 0
            for r in range(32):
                for c in range(32):
                    if idx < len(lines):
                        parts = lines[idx].strip().split()
                        imag_val = parse_hex8(parts[0])
                        real_val = parse_hex8(parts[1])
                        
                        if is_encrypted:
                            # 加密圖：顯示頻譜能量 (Magnitude)
                            img_out[r, c] = np.sqrt(real_val**2 + imag_val**2)
                        else:
                            # 解密圖：直接取實部
                            img_out[r, c] = real_val
                        idx += 1
        return img_out
    except FileNotFoundError:
        print(f"❌ 找不到 {filename}！")
        return None

def normalize_to_255(arr):
    # 神奇的還原魔法：把衰減的微弱訊號，依比例拉伸回 0~255
    arr_min, arr_max = arr.min(), arr.max()
    if arr_max > arr_min:
        return ((arr - arr_min) / (arr_max - arr_min)) * 255.0
    return arr

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "show":
        orig = np.zeros((32, 32))
        img = np.zeros((32, 32), dtype=int)
        img[12:20, :] = 255; img[:, 12:20] = 255
        orig = img
                
        enc = read_hw_output("../pattern/img_enc.txt", is_encrypted=True)
        dec = read_hw_output("../pattern/img_dec.txt", is_encrypted=False)
        
        if enc is not None and dec is not None:
            # 視覺化增強
            enc_vis = normalize_to_255(enc)
            dec_vis = normalize_to_255(dec)
            
            fig, ax = plt.subplots(1, 3, figsize=(15, 5))
            ax[0].imshow(orig, cmap='gray', vmin=0, vmax=255); ax[0].set_title("1. Original Image")
            ax[1].imshow(enc_vis, cmap='turbo'); ax[1].set_title("2. Hardware Encrypted (Key=64)")
            ax[2].imshow(dec_vis, cmap='gray', vmin=0, vmax=255);  ax[2].set_title("3. Hardware Decrypted (Key=-64)")
            plt.tight_layout()
            plt.savefig('hw_2d_encryption_8bit.png')
            print("✅ 成功繪製比對圖 hw_2d_encryption_8bit.png！")
            plt.show()
    else:
        generate_image()