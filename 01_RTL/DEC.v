/********************************************************************
* Filename: DEC.v
* Authors:
*   Yin-Liang Chen
* Description:
*   Final 2-path decoder / recombiner (integer-only arithmetic).
*
* Input format:
*   in_path1_data[32:0] = {flag1, imag1[15:0], real1[15:0]}
*   in_path2_data[32:0] = {flag2, imag2[15:0], real2[15:0]}
*
* Equations (as requested):
*   real = (path1 + path2) * (-2^31) / 32
*   imag = (path1 - path2) * (-2^15) / 32
*
* Here, path values are applied component-wise:
*   real_out uses (real1, real2)
*   imag_out uses (imag1, imag2)
*
* Output format:
*   o_data[31:0] = {imag_out[15:0], real_out[15:0]}
* Review History:
*   2026.04.26  Yin-Liang Chen
*********************************************************************/

module DEC #(
    parameter OUT_W = 16
)(
    input  [32:0] in_path1_data,
    input  [32:0] in_path2_data,
    output [31:0] o_data,
    output [15:0] o_real,
    output [15:0] o_imag
);
    // unpack inputs (flags are currently not used in arithmetic)
    wire signed [15:0] p1_im = in_path1_data[31:16];
    wire signed [15:0] p1_re = in_path1_data[15:0];
    wire signed [15:0] p2_im = in_path2_data[31:16];
    wire signed [15:0] p2_re = in_path2_data[15:0];

    // constants
    localparam signed [63:0] C_REAL = -64'sd2147483648; // -2^31
    localparam signed [63:0] C_IMAG = -64'sd32768;      // -2^15

    // component-wise recombination
    wire signed [63:0] real_full = (($signed(p1_re) + $signed(p2_re)) * C_REAL) >>> 5;
    wire signed [63:0] imag_full = (($signed(p1_im) - $signed(p2_im)) * C_IMAG) >>> 5;

    wire signed [15:0] real_sat = sat16(real_full);
    wire signed [15:0] imag_sat = sat16(imag_full);

    assign o_real = real_sat[15:0];
    assign o_imag = imag_sat[15:0];
    assign o_data = {imag_sat[15:0], real_sat[15:0]};

    function signed [15:0] sat16;
        input signed [63:0] v;
        begin
            if (v > 64'sd32767)
                sat16 = 16'sd32767;
            else if (v < -64'sd32768)
                sat16 = -16'sd32768;
            else
                sat16 = v[15:0];
        end
    endfunction

endmodule

