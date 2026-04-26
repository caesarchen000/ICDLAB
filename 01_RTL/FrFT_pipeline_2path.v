/********************************************************************
* Filename: FrFT_pipeline_2path.v
* Authors:
*   Yin-Liang Chen
* Description:
*   Full modular 2-path pipeline:
*     MUL1 -> FNT -> MUL2 -> IFNT -> MUL3 -> DEC
*
* Interface model:
*   - Preload 32 samples via in_we/in_addr/in_data.
*   - Pulse `start` with key_alpha.
*   - Wait for `done`.
*   - Read output words via out_addr/out_data.
*
* Notes:
*   - Uses the standalone stage modules created in this branch.
*   - This top-level is a control wrapper for staged integration/verification.
* Review History:
*   2026.04.26  Yin-Liang Chen
*********************************************************************/

module FrFT_pipeline_2path #(
    parameter KEY_WIDTH = 8,
    parameter N = 32,
    parameter ADDRW = 5
)(
    input                    clk,
    input                    rst_n,

    // preload 32 input samples (8+8 packed)
    input                    in_we,
    input      [ADDRW-1:0]   in_addr,
    input      [15:0]        in_data,

    // run control
    input                    start,
    input      [KEY_WIDTH-1:0] key_alpha,
    output                   busy,
    output reg               done,

    // readback final 32-bit output words
    input      [ADDRW-1:0]   out_addr,
    output reg [31:0]        out_data
);
    localparam S_IDLE      = 4'd0;
    localparam S_MUL1      = 4'd1;
    localparam S_FNT_LOAD  = 4'd2;
    localparam S_FNT_RUN   = 4'd3;
    localparam S_FNT_READ  = 4'd4;
    localparam S_MUL2      = 4'd5;
    localparam S_IFNT_LOAD = 4'd6;
    localparam S_IFNT_RUN  = 4'd7;
    localparam S_IFNT_READ = 4'd8;
    localparam S_MUL3      = 4'd9;
    localparam S_DEC       = 4'd10;
    localparam S_DONE      = 4'd11;

    reg [3:0] state_r;
    reg [5:0] idx_r;

    reg [15:0] sample_mem [0:N-1];
    reg [32:0] p1_buf [0:N-1];
    reg [32:0] p2_buf [0:N-1];
    reg [31:0] out_mem [0:N-1];

    // ---- Stage module wires ----
    wire [32:0] mul1_p1, mul1_p2;
    wire        mul1_f1, mul1_f2;

    wire [32:0] mul2_p1, mul2_p2;
    wire [32:0] mul3_p1, mul3_p2;

    wire [31:0] dec_data;
    wire [15:0] dec_re, dec_im;

    // FNT engines (path1/path2 in parallel)
    reg        fnt_we_r;
    reg [4:0]  fnt_addr_r;
    reg [32:0] fnt1_din_r, fnt2_din_r;
    reg        fnt_start_r;
    reg [4:0]  fnt_out_addr_r;
    wire [32:0] fnt1_dout, fnt2_dout;
    wire       fnt1_busy, fnt2_busy, fnt1_done, fnt2_done;

    // IFNT engines (path1/path2 in parallel)
    reg        ifnt_we_r;
    reg [4:0]  ifnt_addr_r;
    reg [32:0] ifnt1_din_r, ifnt2_din_r;
    reg        ifnt_start_r;
    reg [4:0]  ifnt_out_addr_r;
    wire [32:0] ifnt1_dout, ifnt2_dout;
    wire       ifnt1_busy, ifnt2_busy, ifnt1_done, ifnt2_done;

    assign busy = (state_r != S_IDLE) && (state_r != S_DONE);

    // ---- Stage modules ----
    MUL1 #(
        .KEY_WIDTH(KEY_WIDTH),
        .IDX_WIDTH(ADDRW)
    ) u_mul1 (
        .i_data(sample_mem[idx_r[4:0]]),
        .key_alpha(key_alpha),
        .lut_idx(idx_r[4:0]),
        .o_path1_flag(mul1_f1),
        .o_path2_flag(mul1_f2),
        .o_path1_data(mul1_p1),
        .o_path2_data(mul1_p2)
    );

    MUL2 #(
        .KEY_WIDTH(KEY_WIDTH),
        .IDX_WIDTH(ADDRW)
    ) u_mul2 (
        .in_path1_data(p1_buf[idx_r[4:0]]),
        .in_path2_data(p2_buf[idx_r[4:0]]),
        .key_alpha(key_alpha),
        .lut_idx(idx_r[4:0]),
        .o_path1_data(mul2_p1),
        .o_path2_data(mul2_p2)
    );

    MUL3 #(
        .KEY_WIDTH(KEY_WIDTH),
        .IDX_WIDTH(ADDRW)
    ) u_mul3 (
        .in_path1_data(p1_buf[idx_r[4:0]]),
        .in_path2_data(p2_buf[idx_r[4:0]]),
        .key_alpha(key_alpha),
        .lut_idx(idx_r[4:0]),
        .o_path1_data(mul3_p1),
        .o_path2_data(mul3_p2)
    );

    DEC u_dec (
        .in_path1_data(p1_buf[idx_r[4:0]]),
        .in_path2_data(p2_buf[idx_r[4:0]]),
        .o_data(dec_data),
        .o_real(dec_re),
        .o_imag(dec_im)
    );

    FNT_butterfly u_fnt1 (
        .clk(clk), .rst_n(rst_n),
        .in_we(fnt_we_r),
        .in_addr(fnt_addr_r),
        .in_data(fnt1_din_r),
        .start(fnt_start_r),
        .busy(fnt1_busy),
        .done(fnt1_done),
        .out_addr(fnt_out_addr_r),
        .out_data(fnt1_dout)
    );

    FNT_butterfly u_fnt2 (
        .clk(clk), .rst_n(rst_n),
        .in_we(fnt_we_r),
        .in_addr(fnt_addr_r),
        .in_data(fnt2_din_r),
        .start(fnt_start_r),
        .busy(fnt2_busy),
        .done(fnt2_done),
        .out_addr(fnt_out_addr_r),
        .out_data(fnt2_dout)
    );

    IFNT_butterfly u_ifnt1 (
        .clk(clk), .rst_n(rst_n),
        .in_we(ifnt_we_r),
        .in_addr(ifnt_addr_r),
        .in_data(ifnt1_din_r),
        .start(ifnt_start_r),
        .busy(ifnt1_busy),
        .done(ifnt1_done),
        .out_addr(ifnt_out_addr_r),
        .out_data(ifnt1_dout)
    );

    IFNT_butterfly u_ifnt2 (
        .clk(clk), .rst_n(rst_n),
        .in_we(ifnt_we_r),
        .in_addr(ifnt_addr_r),
        .in_data(ifnt2_din_r),
        .start(ifnt_start_r),
        .busy(ifnt2_busy),
        .done(ifnt2_done),
        .out_addr(ifnt_out_addr_r),
        .out_data(ifnt2_dout)
    );

    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_r       <= S_IDLE;
            idx_r         <= 6'd0;
            done          <= 1'b0;
            out_data      <= 32'd0;
            fnt_we_r      <= 1'b0;
            fnt_addr_r    <= 5'd0;
            fnt1_din_r    <= 33'd0;
            fnt2_din_r    <= 33'd0;
            fnt_start_r   <= 1'b0;
            fnt_out_addr_r <= 5'd0;
            ifnt_we_r     <= 1'b0;
            ifnt_addr_r   <= 5'd0;
            ifnt1_din_r   <= 33'd0;
            ifnt2_din_r   <= 33'd0;
            ifnt_start_r  <= 1'b0;
            ifnt_out_addr_r <= 5'd0;
            for (k = 0; k < N; k = k + 1) begin
                sample_mem[k] <= 16'd0;
                p1_buf[k] <= 33'd0;
                p2_buf[k] <= 33'd0;
                out_mem[k] <= 32'd0;
            end
        end else begin
            done <= 1'b0;
            fnt_we_r <= 1'b0;
            fnt_start_r <= 1'b0;
            ifnt_we_r <= 1'b0;
            ifnt_start_r <= 1'b0;

            // preload samples allowed in IDLE
            if (state_r == S_IDLE && in_we)
                sample_mem[in_addr] <= in_data;

            // always-available readback
            out_data <= out_mem[out_addr];

            case (state_r)
                S_IDLE: begin
                    idx_r <= 6'd0;
                    if (start) state_r <= S_MUL1;
                end

                S_MUL1: begin
                    p1_buf[idx_r[4:0]] <= mul1_p1;
                    p2_buf[idx_r[4:0]] <= mul1_p2;
                    if (idx_r == 6'd31) begin
                        idx_r <= 6'd0;
                        state_r <= S_FNT_LOAD;
                    end else begin
                        idx_r <= idx_r + 1'b1;
                    end
                end

                S_FNT_LOAD: begin
                    fnt_we_r   <= 1'b1;
                    fnt_addr_r <= idx_r[4:0];
                    fnt1_din_r <= p1_buf[idx_r[4:0]];
                    fnt2_din_r <= p2_buf[idx_r[4:0]];
                    if (idx_r == 6'd31) begin
                        idx_r <= 6'd0;
                        state_r <= S_FNT_RUN;
                    end else begin
                        idx_r <= idx_r + 1'b1;
                    end
                end

                S_FNT_RUN: begin
                    fnt_start_r <= 1'b1; // one-cycle pulse
                    state_r <= S_FNT_READ;
                end

                S_FNT_READ: begin
                    if (fnt1_done && fnt2_done) begin
                        fnt_out_addr_r <= idx_r[4:0];
                        p1_buf[idx_r[4:0]] <= fnt1_dout;
                        p2_buf[idx_r[4:0]] <= fnt2_dout;
                        if (idx_r == 6'd31) begin
                            idx_r <= 6'd0;
                            state_r <= S_MUL2;
                        end else begin
                            idx_r <= idx_r + 1'b1;
                        end
                    end
                end

                S_MUL2: begin
                    p1_buf[idx_r[4:0]] <= mul2_p1;
                    p2_buf[idx_r[4:0]] <= mul2_p2;
                    if (idx_r == 6'd31) begin
                        idx_r <= 6'd0;
                        state_r <= S_IFNT_LOAD;
                    end else begin
                        idx_r <= idx_r + 1'b1;
                    end
                end

                S_IFNT_LOAD: begin
                    ifnt_we_r   <= 1'b1;
                    ifnt_addr_r <= idx_r[4:0];
                    ifnt1_din_r <= p1_buf[idx_r[4:0]];
                    ifnt2_din_r <= p2_buf[idx_r[4:0]];
                    if (idx_r == 6'd31) begin
                        idx_r <= 6'd0;
                        state_r <= S_IFNT_RUN;
                    end else begin
                        idx_r <= idx_r + 1'b1;
                    end
                end

                S_IFNT_RUN: begin
                    ifnt_start_r <= 1'b1; // one-cycle pulse
                    state_r <= S_IFNT_READ;
                end

                S_IFNT_READ: begin
                    if (ifnt1_done && ifnt2_done) begin
                        ifnt_out_addr_r <= idx_r[4:0];
                        p1_buf[idx_r[4:0]] <= ifnt1_dout;
                        p2_buf[idx_r[4:0]] <= ifnt2_dout;
                        if (idx_r == 6'd31) begin
                            idx_r <= 6'd0;
                            state_r <= S_MUL3;
                        end else begin
                            idx_r <= idx_r + 1'b1;
                        end
                    end
                end

                S_MUL3: begin
                    p1_buf[idx_r[4:0]] <= mul3_p1;
                    p2_buf[idx_r[4:0]] <= mul3_p2;
                    if (idx_r == 6'd31) begin
                        idx_r <= 6'd0;
                        state_r <= S_DEC;
                    end else begin
                        idx_r <= idx_r + 1'b1;
                    end
                end

                S_DEC: begin
                    out_mem[idx_r[4:0]] <= dec_data;
                    if (idx_r == 6'd31) begin
                        state_r <= S_DONE;
                    end else begin
                        idx_r <= idx_r + 1'b1;
                    end
                end

                S_DONE: begin
                    done <= 1'b1;
                    state_r <= S_IDLE;
                end

                default: state_r <= S_IDLE;
            endcase
        end
    end

endmodule

