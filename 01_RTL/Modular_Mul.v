/********************************************************************
* Filename: Modular_Mul.v
* Authors:
*     Guan-Yi Tsen
* Description:
*     Modular Multiplier for F_q = 2^32+1
* Note:
*     Data format: [32] = Flag (1 if zero), [31:0] = Value - 1
* Review History:
*     2026.04.18    Guan-Yi Tsen
*********************************************************************/

module Dim1_Modular_Mul #(
    parameter DATA_WIDTH = 33
)(
    input                       clk,
    input      [DATA_WIDTH-1:0] A,
    input      [DATA_WIDTH-1:0] B,
    output     [DATA_WIDTH-1:0] O
);
    // 1. 解碼回真實數值 (0 ~ 2^32)
    wire [32:0] true_A = A[32] ? 33'd0 : {1'b0, A[31:0]} + 33'd1;
    wire [32:0] true_B = B[32] ? 33'd0 : {1'b0, B[31:0]} + 33'd1;

    // 2. 執行乘法 (最大值為 2^32 * 2^32 = 2^64)
    wire [65:0] prod_s1 = true_A * true_B;
    reg  [65:0] prod_s2; //stage 2

    always @(posedge clk) prod_s2 <= prod_s1;

    // 3. Fermat 摺疊: P_L - P_H (mod 2^32+1)
    wire [33:0] P_H = prod_s2[65:32];
    wire [33:0] P_L = {2'b0, prod_s2[31:0]};
    wire signed [34:0] diff = $signed({1'b0, P_L}) - $signed({1'b0, P_H});
    
    // 若為負數則補正 (+ 2^32 + 1)
    wire [33:0] mod_val = diff[34] ? (diff[33:0] + 34'h1_0000_0001) : diff[33:0];

    // 4. 編碼回 Diminished-1
    assign O = (mod_val == 34'd0 || mod_val == 34'h1_0000_0001) ? 
                33'h1_0000_0000 : {1'b0, mod_val[31:0] - 1'b1};
endmodule