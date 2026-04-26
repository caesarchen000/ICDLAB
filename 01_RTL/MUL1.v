/********************************************************************
* Filename: MUL1.v
* Authors:
*   Yin-Liang Chen
* Description:
*   MUL1 front-stage for 2-path flow.
*   All arithmetic is signed integer arithmetic (no floating-point).
*
* Input:
*   - i_data[15:0] = {real[15:8], imag[7:0]}  (8+8 signed)
*   - key_alpha: key / order selector for chirp LUT
*   - lut_idx: sample index
*
* Operation:
*   path1 (flag=1): (x + j*xhat) * (c + j*chat)
*   path2 (flag=0): (x - j*xhat) * (c - j*chat)
*   where x, xhat, c, chat are signed integers.
*
* Output:
*   - two integer-packed 33-bit values:
*       o_path1_data, o_path2_data
*   - explicit path flags:
*       o_path1_flag=1, o_path2_flag=0
*
* Notes:
*   - Uses `Chirp_Generator` from new LUT flow.
*   - For MUL1 stage: sel=0.
*   - path1 uses conj=0, path2 uses conj=1.
* Review History:
*   2026.04.26  Yin-Liang Chen
*********************************************************************/

module MUL1 #(
    parameter KEY_WIDTH = 8,
    parameter IDX_WIDTH = 5
)(
    input  [15:0]                i_data,      // {real[15:8], imag[7:0]}
    input  [KEY_WIDTH-1:0]       key_alpha,
    input  [IDX_WIDTH-1:0]       lut_idx,

    output                       o_path1_flag,
    output                       o_path2_flag,
    output [32:0]                o_path1_data,
    output [32:0]                o_path2_data
);
    // ----------------------------------------------------------------
    // Input unpack (8-bit signed real/imag)
    // ----------------------------------------------------------------
    wire signed [7:0] x    = i_data[15:8];
    wire signed [7:0] xhat = i_data[7:0];

    // ----------------------------------------------------------------
    // Chirp outputs for each path (from Chirp_Generator)
    // ----------------------------------------------------------------
    wire [32:0] c1_raw, c2_raw;
    // Keep stage interface integer-complex by slicing imag/real fields.
    wire signed [15:0] c1_im = c1_raw[31:16];
    wire signed [15:0] c1_re = c1_raw[15:0];
    wire signed [15:0] c2_im = c2_raw[31:16];
    wire signed [15:0] c2_re = c2_raw[15:0];

    Chirp_Generator #(
        .REG_ADDRW(IDX_WIDTH),
        .KEY_WIDTH(KEY_WIDTH),
        .DATA_WIDTH(33)
    ) chirp_p1 (
        .sel(1'b0),
        .conj(1'b0),
        .idx(lut_idx),
        .key(key_alpha),
        .out(c1_raw)
    );

    Chirp_Generator #(
        .REG_ADDRW(IDX_WIDTH),
        .KEY_WIDTH(KEY_WIDTH),
        .DATA_WIDTH(33)
    ) chirp_p2 (
        .sel(1'b0),
        .conj(1'b1),
        .idx(lut_idx),
        .key(key_alpha),
        .out(c2_raw)
    );

    // ----------------------------------------------------------------
    // Complex multiply for both paths
    //
    // path1:
    //   (x + j*xhat)(c + j*chat)
    //   re = x*c - xhat*chat
    //   im = x*chat + xhat*c
    //
    // path2:
    //   (x - j*xhat)(c - j*chat)
    //   re = x*c - xhat*chat
    //   im = -(x*chat + xhat*c)
    // ----------------------------------------------------------------
    wire signed [31:0] p1_re_full = $signed(x) * $signed(c1_re) - $signed(xhat) * $signed(c1_im);
    wire signed [31:0] p1_im_full = $signed(x) * $signed(c1_im) + $signed(xhat) * $signed(c1_re);

    wire signed [31:0] p2_re_full = $signed(x) * $signed(c2_re) - $signed(xhat) * $signed(c2_im);
    wire signed [31:0] p2_im_full = -($signed(x) * $signed(c2_im) + $signed(xhat) * $signed(c2_re));

    // Requested path format: signed 16-bit real + signed 16-bit imag
    wire signed [15:0] p1_re = sat16(p1_re_full);
    wire signed [15:0] p1_im = sat16(p1_im_full);
    wire signed [15:0] p2_re = sat16(p2_re_full);
    wire signed [15:0] p2_im = sat16(p2_im_full);

    assign o_path1_flag = 1'b1;
    assign o_path2_flag = 1'b0;

    // ----------------------------------------------------------------
    // Integer-only packed output (no modular mapping in MUL1)
    // [32] path bit, [31:16] imag16, [15:0] real16
    // ----------------------------------------------------------------
    assign o_path1_data = {1'b1, p1_im[15:0], p1_re[15:0]};
    assign o_path2_data = {1'b0, p2_im[15:0], p2_re[15:0]};

    // ----------------------------------------------------------------
    // Helper functions
    // ----------------------------------------------------------------
    function signed [15:0] sat16;
        input signed [31:0] v;
        begin
            if (v > 32'sd32767)
                sat16 = 16'sd32767;
            else if (v < -32'sd32768)
                sat16 = -16'sd32768;
            else
                sat16 = v[15:0];
        end
    endfunction

endmodule

