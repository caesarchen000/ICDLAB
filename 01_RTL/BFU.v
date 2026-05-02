/********************************************************************
* Filename: BFU.v
* Authors:
*     Guan-Yi Tsen
* Description:
*     Butterfly Unit
* Note:
*     Calculates A + B and (A - B) * psi*k (mod 2^32 + 1)
*     Here, psi = 4
* Review History:
*     2026.05.02    Guan-Yi Tsen
*********************************************************************/

module Dim1_BFU #(
    parameter DATA_WIDTH = 33
)(
    input                   clk,
    input             [4:0] k,          // 旋轉因子指數 (0~15)
    input  [DATA_WIDTH-1:0] A, B,
    output [DATA_WIDTH-1:0] O_add, O_sub
);         
    wire                   [5:0] shift_base;
    wire          [DATA_WIDTH:0] true_A, true_B, mod_sum;
    wire signed [DATA_WIDTH+1:0] sum, temp_sub, folded_sub;
    wire        [DATA_WIDTH-1:0] diff_val, mod_sub, add_result, sub_result;
    wire      [2*DATA_WIDTH-3:0] shifted_diff;
    reg         [DATA_WIDTH-1:0] O_add_reg, O_sub_reg;

    assign shift_base = {1'b0, k} << 1; 

    assign true_A = A[32] ? 34'd0 : {2'b0, A[31:0]} + 34'd1;
    assign true_B = B[32] ? 34'd0 : {2'b0, B[31:0]} + 34'd1;

    // Add
    assign sum = true_A + true_B;
    assign mod_sum = (sum >= 35'h1_0000_0001) ? (sum - 35'h1_0000_0001) : sum[33:0];

    // Sub
    assign temp_sub = $signed({1'b0, true_A}) - $signed({1'b0, true_B});
    assign diff_val = temp_sub[34] ? (temp_sub[32:0] + 33'h1_0000_0001) : temp_sub[32:0];

    assign shifted_diff = diff_val << shift_base;

    // Fermat fold
    wire [33:0] C0 = {2'b0, shifted_diff[31:0]};
    wire [33:0] C1 = {2'b0, shifted_diff[63:32]};
    assign folded_sub = $signed({1'b0, C0}) - $signed({1'b0, C1});
    
    assign mod_sub = folded_sub[34] ? (folded_sub[32:0] + 33'h1_0000_0001) : 
                     (folded_sub >= 35'h1_0000_0001) ? (folded_sub[32:0] - 33'h1_0000_0001) : folded_sub[32:0];

    assign add_result = (mod_sum == 0 || mod_sum == 34'h1_0000_0001) ? 33'h1_0000_0000 : {1'b0, mod_sum[31:0] - 1'b1};
    assign sub_result = (mod_sub == 0 || mod_sub == 34'h1_0000_0001) ? 33'h1_0000_0000 : {1'b0, mod_sub[31:0] - 1'b1};

    always @(posedge clk) begin
        O_add_reg <= add_result;
        O_sub_reg <= sub_result;
    end
    assign O_add = O_add_reg;
    assign O_sub = O_sub_reg;
endmodule
