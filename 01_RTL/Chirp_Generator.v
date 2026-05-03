/********************************************************************
* Filename: Chirp_Generator.v
* Authors:
*     Yu-Yan Zheng
* Description:
*     2 type of chirp signal generation
* Parameters:
*     KEY_WIDTH    : input key width
*     INPUT_WIDTH  : input data width
*     OUTPUT_WIDTH : output data width
*     DATA_WIDTH   : internal calculation data width
*     REG_DEPTH    : how many words in reg file (N = ?)
*     REG_ADDRW    : reg data address width
*     MODULUS      : the choosen Fermat number 
* Note:
*
* Review History:
*     2026.04.26    Yu-Yan Zheng
*********************************************************************/
`timescale 1ns/1ps

module Chirp_Generator_13 #(
    parameter Q_SCALE_1       = 64, // scale for chirp13
    parameter REG_ADDRW       = 5,
    parameter KEY_WIDTH       = 8,
    parameter DATA_WIDTH      = 33,
    parameter LUT_VALUE_WIDTH = 16,
    parameter LUT_DATA_WIDTH  = 2 * LUT_VALUE_WIDTH
)(
    input  wire                  [REG_ADDRW-1:0] idx,
    input  wire signed           [KEY_WIDTH-1:0] key,
    output wire                  [DATA_WIDTH-1:0] path1_out0,
    output wire                  [DATA_WIDTH-1:0] path1_out1,
    output wire                  [DATA_WIDTH-1:0] path2_out0,
    output wire                  [DATA_WIDTH-1:0] path2_out1
);

    localparam [34:0] FQ = 35'h1_0000_0001; // Modulo M = 2^32 + 1
    
    wire [LUT_DATA_WIDTH-1:0] lut_output;
    reg  [DATA_WIDTH-1:0]     out_value [0:3];
    wire [32:0]               val_array [0:3];
    
    assign path1_out0 = out_value[0];
    assign path1_out1 = out_value[1];
    assign path2_out0 = out_value[2];
    assign path2_out1 = out_value[3];

    reg  [3:0] lut_index;
    reg  [6:0] lut_key;

    // --- 1. 解析 LUT 輸出 (轉換為 9-bit 有號數避免 -128 變號溢位) ---
    wire signed [8:0] re0 = $signed(lut_output[7:0]);
    wire signed [8:0] im0 = $signed(lut_output[15:8]);
    wire signed [8:0] re1 = $signed(lut_output[23:16]);
    wire signed [8:0] im1 = $signed(lut_output[31:24]);

    // 取得 Key 符號
    wire key_sign = key[KEY_WIDTH-1];

    // 若 key 為負，原本的角度對應到負角度，等同取共軛 (虛部變號)
    wire signed [8:0] true_im0 = key_sign ? -im0 : im0;
    wire signed [8:0] true_im1 = key_sign ? -im1 : im1;

    // --- 2. 模數轉換函數 ---
    // 將任意有號數安全地轉換至 Modulo M 的正數空間
    function [33:0] to_mod_M;
        input signed [33:0] val_in;
        begin
            if (val_in < 0) begin
                to_mod_M = 34'h1_0000_0001 - $unsigned(-val_in);
            end else begin
                to_mod_M = $unsigned(val_in);
            end
        end
    endfunction

    // --- 3. 模數運算資料路徑 ---
    // 計算 Element 0
    wire [33:0] re0_m     = to_mod_M(re0);
    wire [33:0] im0_m     = to_mod_M(true_im0 <<< 16);  // Im * 2^16
    wire [33:0] neg_im0_m = to_mod_M(-(true_im0 <<< 16)); // -Im * 2^16

    wire [34:0] sum_p1_0  = re0_m + im0_m;
    wire [34:0] sum_p2_0  = re0_m + neg_im0_m;
    
    assign val_array[0] = (sum_p1_0 >= FQ) ? (sum_p1_0 - FQ) : sum_p1_0[32:0]; // Path 1 (key)
    assign val_array[2] = (sum_p2_0 >= FQ) ? (sum_p2_0 - FQ) : sum_p2_0[32:0]; // Path 2 (-key)

    // 計算 Element 1
    wire [33:0] re1_m     = to_mod_M(re1);
    wire [33:0] im1_m     = to_mod_M(true_im1 <<< 16);
    wire [33:0] neg_im1_m = to_mod_M(-(true_im1 <<< 16));

    wire [34:0] sum_p1_1  = re1_m + im1_m;
    wire [34:0] sum_p2_1  = re1_m + neg_im1_m;
    
    assign val_array[1] = (sum_p1_1 >= FQ) ? (sum_p1_1 - FQ) : sum_p1_1[32:0]; // Path 1 (key)
    assign val_array[3] = (sum_p2_1 >= FQ) ? (sum_p2_1 - FQ) : sum_p2_1[32:0]; // Path 2 (-key)

    // --- 4. 處理 LUT 索引與密鑰 ---
    wire [6:0] inv_key_abs = ~key[6:0];
    wire [6:0] key_abs     = key_sign ? inv_key_abs : (key[6:0] - 7'd1);

    // 控制與位址產生邏輯
    integer i;
    always @(*) begin
        lut_index = 0;
        lut_key   = 0;

        if (key == 0) begin
            // Key 為 0 時輸出預設 Scale
            out_value[0] = Q_SCALE_1;
            out_value[1] = Q_SCALE_1;
            out_value[2] = Q_SCALE_1;
            out_value[3] = Q_SCALE_1;
        end else begin
            lut_key   = key_abs;
            // lut_index = (idx > 5'd16) ? (idx - 5'd17) : (5'd15 - idx);
            lut_index = idx[3:0];
            
            // 處理最終數值折減與格式化 (diminished-1 mapping)
            for (i = 0; i < 4; i = i + 1) begin
                if (val_array[i] == 33'd0 || val_array[i] == 33'h1_0000_0001) begin
                    out_value[i] = 33'h1_0000_0000;
                end else begin
                    out_value[i] = {1'b0, val_array[i][31:0] - 1'b1};
                end
            end
        end
    end

    // --- 5. 實例化 LUT 子模組 ---
    LUT_chirp13 #(
        .REG_ADDRW(4),
        .KEY_WIDTH(7)
    ) lut0 (
        .idx(lut_index),
        .key(lut_key),
        .out(lut_output) 
    );

endmodule

module Chirp_Generator_2 #(
    parameter REG_ADDRW  = 4, // 5-1
    parameter KEY_WIDTH  = 8, // choose angle
    parameter DATA_WIDTH = 33,
    parameter LUT_DATA_WIDTH = 66
)(
    input            [REG_ADDRW-1:0] idx,
    input     signed [KEY_WIDTH-1:0] key,
    output           [DATA_WIDTH-1:0] path1_out0,
    output           [DATA_WIDTH-1:0] path1_out1,
    output           [DATA_WIDTH-1:0] path2_out0,
    output           [DATA_WIDTH-1:0] path2_out1
);

    wire [LUT_DATA_WIDTH-1:0] pos_lut_out, neg_lut_out;
    reg  [LUT_DATA_WIDTH-1:0] lut_output0, lut_output1;
    
    assign path1_out0 = lut_output0[DATA_WIDTH-1:0];
    assign path1_out1 = lut_output0[LUT_DATA_WIDTH-1:DATA_WIDTH];
    assign path2_out0 = lut_output1[DATA_WIDTH-1:0];
    assign path2_out1 = lut_output1[LUT_DATA_WIDTH-1:DATA_WIDTH];

    // 取得絕對的正負 Key 值
    wire sign = key[KEY_WIDTH-1]; // 1 代表負數
    wire [KEY_WIDTH-1:0] abs_key = sign ? (~key + 1'b1) : key;
    wire [KEY_WIDTH-1:0] neg_key = sign ? key : (~key + 1'b1);

    // 1. 實體化正角度 LUT (吃 0 ~ 127)
    LUT_chirp2_pos #(
        .REG_ADDRW(4),
        .KEY_WIDTH(8)
    ) lut_pos (
        .idx(idx),
        .key(abs_key),
        .out(pos_lut_out)
    );

    // 2. 實體化負角度 LUT (吃 -1 ~ -128)
    LUT_chirp2_neg #(
        .REG_ADDRW(4),
        .KEY_WIDTH(8)
    ) lut_neg (
        .idx(idx),
        .key(neg_key),
        .out(neg_lut_out)
    );

    // 3. 交叉開關 (Crossbar Switch)
    always @(*) begin
        if (key == 0) begin
            // Key 為 0，兩個 Path 都直接抓 Pos LUT 的結果 (Fan-out 共享)
            lut_output0 = pos_lut_out;
            lut_output1 = pos_lut_out;
        end else if (sign == 1'b0) begin
            // Key 為正，Path 1 拿正，Path 2 拿負
            lut_output0 = pos_lut_out;
            lut_output1 = neg_lut_out;
        end else begin
            // Key 為負，Path 1 拿負，Path 2 拿正 (交叉對調！)
            lut_output0 = neg_lut_out;
            lut_output1 = pos_lut_out;
        end
    end

    // wire [LUT_DATA_WIDTH-1:0] lut_output0, lut_output1;
    
    // reg  [3:0] lut_index;
    // reg  [7:0] lut_key0, lut_key1;
    
    // assign path1_out0 = lut_output0[DATA_WIDTH-1:0];
    // assign path1_out1 = lut_output0[LUT_DATA_WIDTH-1:DATA_WIDTH];
    // assign path2_out0 = lut_output1[DATA_WIDTH-1:0];
    // assign path2_out1 = lut_output1[LUT_DATA_WIDTH-1:DATA_WIDTH];

    // // 控制與位址產生邏輯
    // always @(*) begin
    //     lut_key0  = key; // for path 1
    //     lut_key1  = ~key+1'b1; // for path 2
    //     lut_index = idx;
    // end

    // LUT_chirp2 #(
    //     .REG_ADDRW(4),
    //     .KEY_WIDTH(8)
    // ) lut0 (
    //     .idx(lut_index),
    //     .key(lut_key0),
    //     .out(lut_output0)
    // );

    // LUT_chirp2 #(
    //     .REG_ADDRW(4),
    //     .KEY_WIDTH(8)
    // ) lut (
    //     .idx(lut_index),
    //     .key(lut_key1),
    //     .out(lut_output1)
    // );
endmodule