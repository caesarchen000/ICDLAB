/********************************************************************
* Filename: MUL3.v
* Authors:
*   Yin-Liang Chen
* Description:
*   MUL3 stage for 2-path flow (integer-only arithmetic).
*
* Equation:
*   path1: P1' * (Ct + j*Ct_hat)
*   path2: P2' * (Ct - j*Ct_hat)
*
* Input format:
*   in_path*_data[32:0] = {path_flag, imag[15:0], real[15:0]}
*
* Output format:
*   o_path*_data[32:0] = {path_flag, imag16, real16}
*
* Notes:
*   - Uses `Chirp_Generator` from new LUT flow.
*   - For MUL3 stage: sel=0.
*   - path1 uses conj=0, path2 uses conj=1.
* Review History:
*   2026.04.26  Yin-Liang Chen
*********************************************************************/

module MUL3 #(
    parameter KEY_WIDTH = 8,
    parameter IDX_WIDTH = 5
)(
    input  [32:0]                in_path1_data,
    input  [32:0]                in_path2_data,
    input  [KEY_WIDTH-1:0]       key_alpha,
    input  [IDX_WIDTH-1:0]       lut_idx,

    output [32:0]                o_path1_data,
    output [32:0]                o_path2_data
);
    // ------------------------------------------------------------
    // Unpack path complex values
    // ------------------------------------------------------------
    wire signed [15:0] p1_im = in_path1_data[31:16];
    wire signed [15:0] p1_re = in_path1_data[15:0];
    wire signed [15:0] p2_im = in_path2_data[31:16];
    wire signed [15:0] p2_re = in_path2_data[15:0];

    // ------------------------------------------------------------
    // Chirp outputs for both paths
    // path1 -> (Ct + j*Ct_hat)
    // path2 -> (Ct - j*Ct_hat)
    // ------------------------------------------------------------
    wire [32:0] ct1_raw, ct2_raw;
    wire signed [15:0] ct1_im = ct1_raw[31:16];
    wire signed [15:0] ct1_re = ct1_raw[15:0];
    wire signed [15:0] ct2_im = ct2_raw[31:16];
    wire signed [15:0] ct2_re = ct2_raw[15:0];

    Chirp_Generator #(
        .REG_ADDRW(IDX_WIDTH),
        .KEY_WIDTH(KEY_WIDTH),
        .DATA_WIDTH(33)
    ) chirp_path1 (
        .sel(1'b0),
        .conj(1'b0),
        .idx(lut_idx),
        .key(key_alpha),
        .out(ct1_raw)
    );

    Chirp_Generator #(
        .REG_ADDRW(IDX_WIDTH),
        .KEY_WIDTH(KEY_WIDTH),
        .DATA_WIDTH(33)
    ) chirp_path2 (
        .sel(1'b0),
        .conj(1'b1),
        .idx(lut_idx),
        .key(key_alpha),
        .out(ct2_raw)
    );

    // ------------------------------------------------------------
    // Complex multiplication
    // (a+jb)(c+jd): re=ac-bd, im=ad+bc
    // ------------------------------------------------------------
    wire signed [31:0] o1_re_full = $signed(p1_re) * $signed(ct1_re) - $signed(p1_im) * $signed(ct1_im);
    wire signed [31:0] o1_im_full = $signed(p1_re) * $signed(ct1_im) + $signed(p1_im) * $signed(ct1_re);

    wire signed [31:0] o2_re_full = $signed(p2_re) * $signed(ct2_re) - $signed(p2_im) * $signed(ct2_im);
    wire signed [31:0] o2_im_full = $signed(p2_re) * $signed(ct2_im) + $signed(p2_im) * $signed(ct2_re);

    wire signed [15:0] o1_re = sat16(o1_re_full);
    wire signed [15:0] o1_im = sat16(o1_im_full);
    wire signed [15:0] o2_re = sat16(o2_re_full);
    wire signed [15:0] o2_im = sat16(o2_im_full);

    // keep path flags in outputs, packed as {flag, imag, real}
    assign o_path1_data = {1'b1, o1_im[15:0], o1_re[15:0]};
    assign o_path2_data = {1'b0, o2_im[15:0], o2_re[15:0]};

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

