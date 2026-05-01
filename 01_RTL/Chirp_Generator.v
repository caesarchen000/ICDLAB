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
    parameter Q_SCALE_1 = 64, // scale for chirp13
    parameter Q_SCALE_2 = 32, // scale for chirp2
    parameter REG_ADDRW  = 5,
    parameter KEY_WIDTH  = 8,
    parameter DATA_WIDTH = 16,
    parameter LUT_VALUE_WIDTH = 8,
    parameter LUT_DATA_WIDTH = 2*LUT_VALUE_WIDTH
)(
    input                              sel,
    input              [REG_ADDRW-1:0] idx,
    input  signed      [KEY_WIDTH-1:0] key,
    output        [LUT_DATA_WIDTH-1:0] out
);

    localparam signed [34:0] FQ = 35'h1_0000_0001;

    wire [LUT_DATA_WIDTH-1:0] lut_output0, lut_output1, lut_output;
    reg  [LUT_DATA_WIDTH-1:0] out_value;
    reg  [3:0] lut_index;
    reg  [6:0] lut_key0, lut_key1;
    
    assign out = out_value;
    assign lut_output = sel ? lut_output1 : lut_output0;

    wire key_sign = key[KEY_WIDTH-1];
    //wire neg_img  = key_sign ^ conj;
    /*
    // 解析 LUT 輸出
    wire signed [LUT_VALUE_WIDTH-1:0] lut_output_real = lut_output[LUT_VALUE_WIDTH-1:0];
    wire signed [LUT_VALUE_WIDTH-1:0] lut_output_img  = lut_output[LUT_DATA_WIDTH-1:LUT_VALUE_WIDTH];
    
    wire signed [LUT_VALUE_WIDTH-1:0] lut_real = lut_output_real;
    wire signed [LUT_VALUE_WIDTH-1:0] lut_img  = neg_img ? (~lut_output_img + 1'b1) : lut_output_img;

    // 模數運算資料路徑 (完全組合邏輯，避免 Delta-Cycle 延遲)
    wire signed [34:0] re_ext = $signed(lut_real);
    wire [32:0] re_mod = (re_ext < 0) ? (re_ext + FQ) : re_ext[32:0];

    wire signed [34:0] im_shift = $signed(lut_img) <<< 16;
    wire [32:0] im_mod = (im_shift < 0) ? (im_shift + FQ) : im_shift[32:0];

    wire [33:0] sum = re_mod + im_mod;
    wire [32:0] val = (sum >= FQ[32:0]) ? (sum - FQ[32:0]) : sum[32:0];
    */

     // 處理 LUT 索引與密鑰
    wire [6:0] inv_key_abs = ~key[6:0];
    wire [6:0] key_abs = key_sign ? inv_key_abs : (key[6:0] - 7'd1);

    // 控制與位址產生邏輯
    always @(*) begin
        lut_index = 0;
        lut_key0  = 0;
        lut_key1  = 0;

        if (key == 0 || idx == 5'd16) begin
            out_value = sel? Q_SCALE_2 : Q_SCALE_1; //no img, real = 1*Scale
        end else begin
            lut_key0  = key_abs;
            lut_key1  = key_abs;
            //lut_key1  = (key_abs > 7'd63) ? (7'd126 - key_abs) : key_abs;
            lut_index = (idx > 5'd16) ? (idx - 5'd17) : (5'd15 - idx);
            
            // 處理最終數值折減
            out_value = lut_output;
            /*
            if (val == 33'd0 || val == 33'h1_0000_0001) begin
                out_value = 33'h1_0000_0000;
            end else begin
                out_value = {1'b0, val[31:0] - 1'b1};
            end
            */
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
        .KEY_WIDTH(7)
    ) lut1 (
        .idx(lut_index),
        .key(lut_key1),
        .out(lut_output1)
    );

endmodule