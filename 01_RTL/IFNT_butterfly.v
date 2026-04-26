/********************************************************************
* Filename: IFNT_butterfly.v
* Authors:
*   Yin-Liang Chen
* Description:
*   Standalone 32-point inverse FNT engine using butterfly method.
*
* Notes:
*   - Uses existing `RegFile` and `Dim1_BFU`.
*   - Inverse FNT schedule, 5 stages x 16 butterflies = 80 cycles.
*   - Data format is the same 33-bit format used in current RTL blocks.
*
* Usage:
*   1) Preload 32 words through `in_we/in_addr/in_data`.
*   2) Pulse `start`.
*   3) Wait for `done`.
*   4) Read transformed words via `out_addr/out_data`.
* Review History:
*   2026.04.26  Yin-Liang Chen
*********************************************************************/

module IFNT_butterfly #(
    parameter DATA_WIDTH = 33,
    parameter REG_DEPTH  = 32,
    parameter REG_ADDRW  = 5
)(
    input                       clk,
    input                       rst_n,

    // preload interface
    input                       in_we,
    input      [REG_ADDRW-1:0]  in_addr,
    input      [DATA_WIDTH-1:0] in_data,

    // run control
    input                       start,
    output                      busy,
    output reg                  done,

    // readback interface
    input      [REG_ADDRW-1:0]  out_addr,
    output     [DATA_WIDTH-1:0] out_data
);
    reg running_r;
    reg [6:0] counter_r; // 0..79

    wire [2:0] fnt_stage;
    wire [3:0] fnt_bfly;
    assign {fnt_stage, fnt_bfly} = counter_r;

    reg  [4:0] idxA, idxB, idxA_reverse, idxB_reverse;
    reg  [3:0] twiddle_k;

    // RegFile signals
    reg  [REG_ADDRW-1:0] rf_read_addr_1, rf_read_addr_2;
    wire [DATA_WIDTH-1:0] rf_read_data_1, rf_read_data_2;
    reg  [REG_ADDRW-1:0] rf_write_addr_1, rf_write_addr_2;
    reg  [DATA_WIDTH-1:0] rf_write_data_1, rf_write_data_2;
    reg                   rf_wen1, rf_wen2;

    // BFU signals
    reg  [4:0] bfu_shift;
    reg  [DATA_WIDTH-1:0] bfu_in_1, bfu_in_2;
    wire [DATA_WIDTH-1:0] bfu_add_out, bfu_sub_out;

    assign busy = running_r;
    assign out_data = rf_read_data_1;

    // ------------------------------------------------------------
    // Address + twiddle generator
    // ------------------------------------------------------------
    always @(*) begin
        idxA = 5'd0;
        idxB = 5'd0;
        twiddle_k = 4'd0;

        case (fnt_stage)
            3'd0: twiddle_k = fnt_bfly;
            3'd1: twiddle_k = {fnt_bfly[2:0], 1'b0};
            3'd2: twiddle_k = {fnt_bfly[1:0], 2'b0};
            3'd3: twiddle_k = {fnt_bfly[0], 3'b0};
            3'd4: twiddle_k = 4'b0;
            default: twiddle_k = 4'b0;
        endcase

        case (fnt_stage)
            3'd0: begin
                idxA = {1'b0, fnt_bfly};
                idxB = {1'b1, fnt_bfly};
            end
            3'd1: begin
                idxA = {fnt_bfly[3], 1'b0, fnt_bfly[2:0]};
                idxB = {fnt_bfly[3], 1'b1, fnt_bfly[2:0]};
            end
            3'd2: begin
                idxA = {fnt_bfly[3:2], 1'b0, fnt_bfly[1:0]};
                idxB = {fnt_bfly[3:2], 1'b1, fnt_bfly[1:0]};
            end
            3'd3: begin
                idxA = {fnt_bfly[3:1], 1'b0, fnt_bfly[0]};
                idxB = {fnt_bfly[3:1], 1'b1, fnt_bfly[0]};
            end
            3'd4: begin
                idxA = {fnt_bfly, 1'b0};
                idxB = {fnt_bfly, 1'b1};
            end
            default: begin
                idxA = 5'd0;
                idxB = 5'd0;
            end
        endcase

        idxA_reverse = {idxA[0], idxA[1], idxA[2], idxA[3], idxA[4]};
        idxB_reverse = {idxB[0], idxB[1], idxB[2], idxB[3], idxB[4]};
    end

    // ------------------------------------------------------------
    // Datapath control
    // ------------------------------------------------------------
    always @(*) begin
        // defaults
        rf_read_addr_1  = out_addr;
        rf_read_addr_2  = {REG_ADDRW{1'b0}};
        rf_write_addr_1 = {REG_ADDRW{1'b0}};
        rf_write_addr_2 = {REG_ADDRW{1'b0}};
        rf_write_data_1 = {DATA_WIDTH{1'b0}};
        rf_write_data_2 = {DATA_WIDTH{1'b0}};
        rf_wen1 = 1'b0;
        rf_wen2 = 1'b0;

        bfu_shift = 5'd0;
        bfu_in_1  = {DATA_WIDTH{1'b0}};
        bfu_in_2  = {DATA_WIDTH{1'b0}};

        if (running_r) begin
            rf_read_addr_1  = idxA_reverse;
            rf_read_addr_2  = idxB_reverse;

            if (twiddle_k == 4'd0) begin
                bfu_shift = 5'd0;
                bfu_in_1  = rf_read_data_1;
                bfu_in_2  = rf_read_data_2;
            end else begin
                bfu_shift = 5'd16 - {1'b0, twiddle_k};
                bfu_in_1  = rf_read_data_2;
                bfu_in_2  = rf_read_data_1;
            end

            rf_write_addr_1 = idxA_reverse;
            rf_write_addr_2 = idxB_reverse;
            rf_write_data_1 = bfu_add_out;
            rf_write_data_2 = bfu_sub_out;
            rf_wen1         = 1'b1;
            rf_wen2         = 1'b1;
        end

        // preload has priority when not running
        if (!running_r && in_we) begin
            rf_write_addr_1 = in_addr;
            rf_write_data_1 = in_data;
            rf_wen1         = 1'b1;
            rf_wen2         = 1'b0;
        end
    end

    // ------------------------------------------------------------
    // Run control
    // ------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            running_r <= 1'b0;
            counter_r <= 7'd0;
            done      <= 1'b0;
        end else begin
            done <= 1'b0;

            if (!running_r) begin
                if (start) begin
                    running_r <= 1'b1;
                    counter_r <= 7'd0;
                end
            end else begin
                if (counter_r == 7'd79) begin
                    running_r <= 1'b0;
                    counter_r <= 7'd0;
                    done      <= 1'b1;
                end else begin
                    counter_r <= counter_r + 1'b1;
                end
            end
        end
    end

    // ------------------------------------------------------------
    // Submodules
    // ------------------------------------------------------------
    RegFile #(
        .DATA_WIDTH(DATA_WIDTH),
        .REG_DEPTH(REG_DEPTH),
        .REG_ADDRW(REG_ADDRW)
    ) regfile (
        .clk(clk),
        .read_addr_1(rf_read_addr_1),
        .read_addr_2(rf_read_addr_2),
        .read_data_1(rf_read_data_1),
        .read_data_2(rf_read_data_2),
        .wen1(rf_wen1),
        .wen2(rf_wen2),
        .write_addr_1(rf_write_addr_1),
        .write_addr_2(rf_write_addr_2),
        .write_data_1(rf_write_data_1),
        .write_data_2(rf_write_data_2)
    );

    Dim1_BFU #(
        .DATA_WIDTH(DATA_WIDTH)
    ) bfu (
        .k(bfu_shift),
        .A(bfu_in_1),
        .B(bfu_in_2),
        .O_add(bfu_add_out),
        .O_sub(bfu_sub_out)
    );

endmodule

