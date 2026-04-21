import numpy as np
from PIL import Image
import os

IMG_SIZE = 640
CHANNELS = 3
N = 32

def image_to_txt(input_img_path, output_txt_path):
    print(f"[*] 讀取影像: {input_img_path} ...")
    img = Image.open(input_img_path).convert('RGB').resize((IMG_SIZE, IMG_SIZE))
    img_array = np.array(img).flatten()
    assert len(img_array) % N == 0, "Image size must be divisible by N=32"
    
    with open(output_txt_path, 'w') as f:
        for val in img_array:
            f.write(f"{val:04X}\n")
    print(f"[+] 已匯出 {len(img_array)} pixels 至 {output_txt_path}")

def txt_to_image(txt_path, output_img_path, is_decrypted=False):
    action = "解密還原" if is_decrypted else "加密視覺化"
    print(f"[*] 讀取硬體資料進行 {action}: {txt_path} ...")
    
    pixels = []
    with open(txt_path, 'r') as f:
        lines = f.readlines()
        
    num_blocks = (IMG_SIZE * IMG_SIZE * CHANNELS) // N
    idx = 0
    
    for b in range(num_blocks):
        idx += 4 # 跳過硬體輸出的 4 Bytes Flag
        
        for w in range(N):
            # 每個 Payload 有 4 Bytes (32-bit)，我們抓最低位的 Byte3 當作像素顏色
            # 在解密還原時，高位元本來就全為 0，所以最低位就是真實無損的像素值！
            b3 = int(lines[idx].strip(), 16)
            b2 = int(lines[idx+1].strip(), 16)
            b1 = int(lines[idx+2].strip(), 16)
            b0 = int(lines[idx+3].strip(), 16) 
            idx += 4
            
            pixels.append(b0)

    img_array = np.array(pixels, dtype=np.uint8).reshape((IMG_SIZE, IMG_SIZE, CHANNELS))
    img = Image.fromarray(img_array, 'RGB')
    img.save(output_img_path)
    img.show()
    print(f"[+] 影像已儲存至 {output_img_path} 並顯示！")

if __name__ == "__main__":
    # --- 流程一：產生原始資料 ---
    if os.path.exists("../pattern/imag/input.jpg") and not os.path.exists("../pattern/img_input.txt"):
        image_to_txt("../pattern/imag/input.jpg", "../pattern/img_input.txt")
        
    # --- 流程二：視覺化加密結果 (執行完 tb_FrFT_image 後) ---
    if os.path.exists("../pattern/img_encoded.txt"):
        txt_to_image("../pattern/img_encoded.txt", "../pattern/imag/encoded_output.png", is_decrypted=False)
        
    # --- 流程三：視覺化解密還原結果 (執行完 tb_FrFT_image_dec 後) ---
    if os.path.exists("../pattern/img_decoded.txt"):
        txt_to_image("../pattern/img_decoded.txt", "../pattern/imag/decoded_output.png", is_decrypted=True)