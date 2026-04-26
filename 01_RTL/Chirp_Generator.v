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

module Chirp_Generator #(
    parameter REG_ADDRW  = 5,
    parameter KEY_WIDTH  = 8,
    parameter DATA_WIDTH = 33,
    parameter LUT_VALUE_WIDTH = 9,
    parameter LUT_DATA_WIDTH = 2*LUT_VALUE_WIDTH
)(
    input                            sel,
    input                            conj,
    input            [REG_ADDRW-1:0] idx,
    input     signed [KEY_WIDTH-1:0] key,
    output           [DATA_WIDTH-1:0] out
);

    localparam signed [34:0] FQ = 35'h1_0000_0001;
    
    wire [LUT_DATA_WIDTH-1:0] lut_output0, lut_output1, lut_output;
    reg  [32:0] out_value;
    
    reg  [3:0] lut_index;
    reg  [6:0] lut_key0;
    reg  [5:0] lut_key1;
    
    assign out = out_value;
    assign lut_output = sel ? lut_output1 : lut_output0;

    // 解析 LUT 輸出
    wire signed [LUT_VALUE_WIDTH-1:0] lut_output_real = lut_output[LUT_VALUE_WIDTH-1:0];
    wire signed [LUT_VALUE_WIDTH-1:0] lut_output_img  = lut_output[LUT_DATA_WIDTH-1:LUT_VALUE_WIDTH];

    // 符號控制與共軛運算
    wire key_sign = key[KEY_WIDTH-1];
    wire neg_img  = key_sign ^ conj;
    
    wire signed [LUT_VALUE_WIDTH-1:0] lut_real = lut_output_real;
    wire signed [LUT_VALUE_WIDTH-1:0] lut_img  = neg_img ? (~lut_output_img + 1'b1) : lut_output_img;

    // 模數運算資料路徑 (完全組合邏輯，避免 Delta-Cycle 延遲)
    wire signed [34:0] re_ext = $signed(lut_real);
    wire [32:0] re_mod = (re_ext < 0) ? (re_ext + FQ) : re_ext[32:0];

    wire signed [34:0] im_shift = $signed(lut_img) <<< 16;
    wire [32:0] im_mod = (im_shift < 0) ? (im_shift + FQ) : im_shift[32:0];

    wire [33:0] sum = re_mod + im_mod;
    wire [32:0] val = (sum >= FQ[32:0]) ? (sum - FQ[32:0]) : sum[32:0];

     // 處理 LUT 索引與密鑰
    wire [6:0] inv_key_abs = ~key[6:0];
    wire [6:0] key_abs = key_sign ? inv_key_abs : (key[6:0] - 7'd1);

    // 控制與位址產生邏輯
    always @(*) begin
        lut_index = 0;
        lut_key0  = 0;
        lut_key1  = 0;

        if (key == 0 || idx == 5'd16) begin
            out_value = 33'd127;
        end else begin
            
            lut_key0  = key_abs;
            lut_key1  = (key_abs > 7'd63) ? (7'd126 - key_abs) : key_abs;
            lut_index = (idx > 5'd16) ? (idx - 5'd17) : (5'd15 - idx);
            
            // 處理最終數值折減
            if (val == 33'd0 || val == 33'h1_0000_0001) begin
                out_value = 33'h1_0000_0000;
            end else begin
                out_value = {1'b0, val[31:0] - 1'b1};
            end
        end
    end

    // 實例化子模組 (請確保子模組內的 output 變數名稱已更改為 out_data)
    LUT_chirp13 #(
        .REG_ADDRW(4),
        .KEY_WIDTH(7)
    ) lut0 (
        .idx(lut_index),
        .key(lut_key0),
        .out(lut_output0) 
    );

    LUT_chirp2 #(
        .REG_ADDRW(4),
        .KEY_WIDTH(6)
    ) lut1 (
        .idx(lut_index),
        .key(lut_key1[5:0]),
        .out(lut_output1)
    );

endmodule

/*
module Chirp_Generator #(
    parameter REG_ADDRW  = 5,
    parameter KEY_WIDTH  = 8,
    parameter DATA_WIDTH = 33,
    parameter LUT_VALUE_WIDTH = 9,
    parameter LUT_DATA_WIDTH = 2*LUT_VALUE_WIDTH
)(
    input                         sel,
    input                         conj,
    input         [REG_ADDRW-1:0] idx,
    input  signed [KEY_WIDTH-1:0] key, // -128 ~ 127
    output reg   [DATA_WIDTH-1:0] out
);

    localparam signed [34:0] FQ = 35'h0_1_0000_0001;
    wire [LUT_DATA_WIDTH-1:0] lut_output0, lut_output1, lut_output;

    reg signed [LUT_VALUE_WIDTH-1:0] lut_output_real, lut_output_img, lut_real, lut_img;
    reg neg_img; // = 1 : X-jY ; = 0 : X+jY
    reg [3:0] lut_index;
    reg [6:0] lut_key0;
    reg [5:0] lut_key1;
    reg [7:0] inv_key; // ~key
    reg [6:0] key_abs; // abs(key)-1
    reg key_sign;
    reg [32:0] out_value; // 33 bits

    assign out = out_value;
    assign lut_output = sel? lut_output1 : lut_output0;
    
    // 1. 處理 Real Part (直接擴展並檢查符號)
    wire signed [34:0] re_ext = $signed(lut_real);
    wire [32:0] re_mod = (re_ext < 0) ? (re_ext + FQ) : re_ext[32:0];

    // 2. 處理 Imaginary Part (先位移，後取模)
    wire signed [34:0] im_shift = $signed(lut_img) <<< 16;
    wire [32:0] im_mod = (im_shift < 0) ? (im_shift + FQ) : im_shift[32:0];

    // 3. 兩者相加與最終模運算
    // re_mod 與 im_mod 最大皆為 FQ-1，相加最大約為 2*FQ，因此只需減去一次 FQ
    wire [33:0] sum = re_mod + im_mod;
    wire [32:0] val = (sum >= FQ[32:0]) ? (sum - FQ[32:0]) : sum[32:0];

    always@(*)begin
        
        key_sign    = key[KEY_WIDTH-1]; // sign bit
        inv_key     = ~key;
        key_abs     = 0;
        lut_key0    = 0;
        lut_key1    = 0;
        neg_img     = key_sign^conj;
        out_value   = 0;
        lut_index   = 0;

        lut_output_real = lut_output[LUT_VALUE_WIDTH-1:0];
        lut_output_img  = lut_output[LUT_DATA_WIDTH-1:LUT_VALUE_WIDTH];

        lut_real = lut_output_real;
        lut_img = lut_output_img;

        if(key == 0 || idx == 5'd16) begin
            // idx == 16 means at center of [-16, 15]
            out_value   = 33'd127; // (1+0j)*128(quantize scale)-1(dimish 1)=127
        end
        else begin
            // consider abs(key)-1 = 1-1, 2-1, ..., (128-1)
            key_abs     = key_sign? inv_key[6:0] : (key[6:0]-7'd1);
            lut_key0    = key_abs;
            lut_key1    = (key_abs > 7'd63)? (7'd126-key_abs) : key_abs; // can't handle key_abs = 7'd127
            lut_index   = (idx > 5'd16)? (idx-5'd17) : (5'd15-idx); // leverage the symmetry within index [-16, 15]
            
            lut_real    = lut_output_real;
            lut_img     = neg_img? (~lut_output_img)+1'b1 : lut_output_img;
            // diminsh 1
            out_value   = (val == 33'd0 || val == 33'h1_0000_0001) ? 33'h1_0000_0000 : {1'b0, val[31:0] - 1'b1};

        end
    end

    LUT_chirp13 #(
        .REG_ADDRW(4),
        .KEY_WIDTH(7)
    ) lut0 (
        .idx(lut_index),
        .key(lut_key0),
        .output(lut_output0)
    );

    LUT_chirp2 #(
        .REG_ADDRW(4),
        .KEY_WIDTH(6)
    ) lut1 (
        .idx(lut_index),
        .key(lut_key1[5:0]),
        .output(lut_output1)
    );

endmodule
*/