module ROM_Wrapper_Odd (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,         // 配合 MAC 的 is_computing
    input  wire [4:0]  n_in,       // 原始的 0~31 索引
    input  wire [4:0]  k_idx,
    
    // 過完 Pipeline 的輸出，直接接給 PE
    output reg  [1:0]  reg_sign1, reg_sign2, reg_sign3,
    output reg  [3:0]  reg_shift1, reg_shift2, reg_shift3
);

    // ==========================================
    // 1. 位址對摺 (Address Folding)
    // ==========================================
    // 強制把 17~31 映射回 15~1 (注意：32-n 在硬體裡用減法即可)
    wire [4:0] fold_n = (n_in > 5'd16) ? -n_in : n_in;
    
    // ==========================================
    // 2. 實例化「被砍半」的實體 ROM (0~16)
    // ==========================================
    wire [1:0] raw_s1, raw_s2, raw_s3;
    wire [3:0] raw_h1, raw_h2, raw_h3;
    
    // 這個 CSD_ROM_Table_odd 只需要存 n=0~16 的資料！
    CSD_ROM_Table_odd rom_inst (
        .n_idx(fold_n), .k_idx(k_idx),
        .sign1(raw_s1), .shift1(raw_h1),
        .sign2(raw_s2), .shift2(raw_h2),
        .sign3(raw_s3), .shift3(raw_h3)
    );

    // ==========================================
    // 3. 符號翻轉邏輯 (Sign Flipping)
    // ==========================================
    // 數學物理意義：當 k=31 時視為偶數階，其餘看 LSB
    wire is_k_odd = (k_idx == 5'd31) ? 1'b0 : k_idx[0]; 
    
    // 不管是 Even 還是 Odd Wrapper，只要超過中心且 k 是奇數，就必須翻轉！
    wire need_flip = (n_in > 5'd16) && is_k_odd;
    
    wire [1:0] final_s1 = {raw_s1[1], raw_s1[0] ^ need_flip};
    wire [1:0] final_s2 = {raw_s2[1], raw_s2[0] ^ need_flip};
    wire [1:0] final_s3 = {raw_s3[1], raw_s3[0] ^ need_flip};

    // ==========================================
    // 4. Pipeline 暫存器 (切斷 Critical Path)
    // ==========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_sign1 <= 2'b10; reg_sign2 <= 2'b10; reg_sign3 <= 2'b10;
            reg_shift1 <= 4'd0; reg_shift2 <= 4'd0; reg_shift3 <= 4'd0;
        end else if (en) begin
            // 把翻轉後的符號跟原封不動的 shift 存起來
            reg_sign1 <= final_s1; reg_shift1 <= raw_h1;
            reg_sign2 <= final_s2; reg_shift2 <= raw_h2;
            reg_sign3 <= final_s3; reg_shift3 <= raw_h3;
        end
    end

endmodule

module ROM_Wrapper_Even (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,         // 配合 MAC 的 is_computing
    input  wire [4:0]  n_in,       // 原始的 0~31 索引
    input  wire [4:0]  k_idx,
    
    // 過完 Pipeline 的輸出，直接接給 PE
    output reg  [1:0]  reg_sign1, reg_sign2, reg_sign3,
    output reg  [3:0]  reg_shift1, reg_shift2, reg_shift3
);

    // ==========================================
    // 1. 位址對摺 (Address Folding)
    // ==========================================
    // 強制把 17~31 映射回 15~1 (注意：32-n 在硬體裡用減法即可)
    wire [4:0] fold_n = (n_in > 5'd16) ? -n_in : n_in;
    
    // ==========================================
    // 2. 實例化「被砍半」的實體 ROM (0~16)
    // ==========================================
    wire [1:0] raw_s1, raw_s2, raw_s3;
    wire [3:0] raw_h1, raw_h2, raw_h3;
    
    // 這個 CSD_ROM_Table_odd 只需要存 n=0~16 的資料！
    CSD_ROM_Table_even rom_inst (
        .n_idx(fold_n), .k_idx(k_idx),
        .sign1(raw_s1), .shift1(raw_h1),
        .sign2(raw_s2), .shift2(raw_h2),
        .sign3(raw_s3), .shift3(raw_h3)
    );

    
    // ==========================================
    // 3. 符號翻轉邏輯 (Sign Flipping)
    // ==========================================
    // 數學物理意義：當 k=31 時視為偶數階，其餘看 LSB
    wire is_k_odd = (k_idx == 5'd31) ? 1'b0 : k_idx[0]; 
    
    // 不管是 Even 還是 Odd Wrapper，只要超過中心且 k 是奇數，就必須翻轉！
    wire need_flip = (n_in > 5'd16) && is_k_odd;
    
    wire [1:0] final_s1 = {raw_s1[1], raw_s1[0] ^ need_flip};
    wire [1:0] final_s2 = {raw_s2[1], raw_s2[0] ^ need_flip};
    wire [1:0] final_s3 = {raw_s3[1], raw_s3[0] ^ need_flip};

    // ==========================================
    // 4. Pipeline 暫存器 (切斷 Critical Path)
    // ==========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_sign1 <= 2'b10; reg_sign2 <= 2'b10; reg_sign3 <= 2'b10;
            reg_shift1 <= 4'd0; reg_shift2 <= 4'd0; reg_shift3 <= 4'd0;
        end else if (en) begin
            // 把翻轉後的符號跟原封不動的 shift 存起來
            reg_sign1 <= final_s1; reg_shift1 <= raw_h1;
            reg_sign2 <= final_s2; reg_shift2 <= raw_h2;
            reg_sign3 <= final_s3; reg_shift3 <= raw_h3;
        end
    end

endmodule