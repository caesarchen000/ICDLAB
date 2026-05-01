/********************************************************************
* Filename: FrFT_top.v
* Authors:
*     Guan-Yi Tsen, Yu-Yan Zheng
* Description:
*     Fractional Fourier Transform Core
* Parameters:
*     IOPORT_IN_W   : width of input data
*     IOPORT_OUT_W  : width of output data
*     LUT_WIDTH     : data width of lut output
*     DATA_WIDTH    : internal calculation data width
*     NZ_DATA_WIDTH : data width without flag
*     REG_DEPTH     : how many words in reg file (N = ?)
*     REG_ADDRW     : reg data address width
*     LOAD_CYCLE    : cycle needs for load data / output data
*     MUL_CYCLE     : cycle needs for MUL (16 for 2*MOD_MUL)
*     FNT_CYCLE     : cycle needs for FNT and IFNT (40 for 2*BFU)
* Note:
*
* Review History:
*     2026.04.28    Guan-Yi Tsen
*********************************************************************/

module FrFT_top #(
    parameter IOPORT_IN_W   = 16, // 16-bit Input Pin
    parameter IOPORT_OUT_W  = 12, // 12-bit Output Pin
    parameter LUT_WIDTH     = 16, // 16-bit look up table output
    parameter DATA_WIDTH    = 33, // 1-bit Flag + 32-bit Data
    parameter NZ_DATA_WIDTH = 32, // 32-bit non zero data (no flag)
    parameter KEY_WIDTH     = 8,
    parameter REG_DEPTH     = 32, // N = 32
    parameter REG_ADDRW     = $clog2(REG_DEPTH),
    parameter LOAD_CYCLE    = 7'd32,
    parameter MUL_CYCLE     = 7'd16,
    parameter FNT_CYCLE     = 7'd40
)(
    input                     clk,
    input                     rst_n, // asynchronous reset

    // input & output control signals
    input                     i_valid,
    output                    i_ready,
    input                     o_ready,
    output                    o_valid,

    // input & output data
    input   [IOPORT_IN_W-1:0] i_data,
    output [IOPORT_OUT_W-1:0] o_data
);
    // state parameter
    localparam S_IDLE = 3'd0; // wait for i_ready to load key
    localparam S_STAL = 3'd1; // stall for chirp2 load and FNT
    localparam S_LOAD = 3'd2; // load data
    localparam S_EXEC = 3'd3; // exec 
    localparam S_DONE = 3'd4; // assert o_valid, wait for o_ready to output preamble
    localparam S_DOUT = 3'd5; // data out

    // constant for scaling in final decode stage
    parameter REAL_PATH1_SCALE = 33'h0_fc00_0000;
    parameter IMAG_PATH1_SCALE = 33'h0_ffff_fc00;
    parameter REAL_PATH2_SCALE = 33'h0_fc00_0000;
    parameter IMAG_PATH2_SCALE = 33'h0_0000_03ff;

    // control & state signal declaration
    reg             [3:0] state_r, state_w;
    reg             [6:0] counter_r, counter_w;
    
    // key register
    reg   [KEY_WIDTH-1:0] key_r, key_w;

    // LUT signals
    reg                   lut_sel;
    reg   [REG_ADDRW-1:0] lut_idx;
    wire  [LUT_WIDTH-1:0] lut_out; // {8'imag, 8'real}

    // Core interface signals
    wire  [1:0] core_i_ready, core_o_valid;
    reg  [31:0] core_i_data;
    reg  [15:0] core_chirp2_data, core_chirp3_data;
    reg  [32:0] pos_result_r, neg_result_r;
    wire [32:0] pos_result_w, neg_result_w;

    function signed [33:0] decode_dim1;
        input [32:0] dim1_val;
        reg [33:0] actual_val;
        begin
            if (dim1_val[32] == 1'b1) begin
                // Special case: Dim-1 represents 0
                actual_val = 34'sd0;
            end else begin
                // Restore value: dim1_val + 1
                actual_val = {1'b0, dim1_val[31:0]} + 34'd1;
                
                // If it's in the upper half of the Fermat field, it's a negative number
                if (actual_val > 34'h0_7FFF_FFFF) begin
                    actual_val = actual_val - 34'h1_0000_0001; // Subtract 2^32 + 1
                end
            end
            decode_dim1 = actual_val;
        end
    endfunction

    // ====================================================================
    // IO interface
    // ====================================================================
    reg input_ready_r, input_ready_w, output_valid_r, output_valid_w;
    assign i_ready = input_ready_r;
    assign o_valid = output_valid_r;

    wire signed [33:0] decoded_pos = decode_dim1(pos_result_r);
    wire signed [33:0] decoded_neg = decode_dim1(neg_result_r);
    wire signed [34:0] final_sum = decoded_pos + decoded_neg;
    assign o_data  = final_sum[28:17]; // 18 bit with scale = 64^3

    always @(*) begin
        key_w          = key_r;
        state_w        = state_r;
        counter_w      = counter_r;
        input_ready_w  = input_ready_r;
        output_valid_w = output_valid_r;
        lut_sel = 0; lut_idx  = 0;
        core_i_data      = 32'd0;
        core_chirp2_data = 16'd0;
        core_chirp3_data = 16'd0;
        
        case(state_r)
            S_IDLE : begin
                input_ready_w  = 1'b1;
                output_valid_w = 1'b0;

                if (i_valid) begin
                    state_w    = S_STAL;
                    key_w      = i_data[KEY_WIDTH-1:0];
                    counter_w  = 0;
                end
            end
            S_STAL : begin
                lut_sel = 1'b1; // for chirp2
                lut_idx = counter_r[4:0];
                core_chirp2_data = lut_out;
                
                if (counter_r == 7'd111) begin
                    state_w   = S_LOAD;
                    counter_w = 0;
                end else begin
                    counter_w = counter_r + 1;
                end
            end
            S_LOAD : begin
                input_ready_w = 1'b1;
                lut_sel = 1'b0; // for chirp 1
                lut_idx = counter_r[4:0];
                
                if (i_valid) begin
                    counter_w = counter_r + 1;
                    core_i_data = {lut_out, i_data};
                    
                    if (counter_r == LOAD_CYCLE - 1) begin
                        state_w       = S_EXEC;
                        input_ready_w = 1'b0;
                        counter_w     = 0;
                    end
                end
            end
            S_EXEC : begin
                lut_sel = 1'b0; // for chirp 3
                lut_idx = counter_r[4:0];
                core_chirp3_data = lut_out;
                
                if (core_i_ready[0] & core_i_ready[1]) begin
                    counter_w = counter_r + 1;
                    if (counter_r == LOAD_CYCLE - 1) begin
                        state_w   = S_DONE;
                        counter_w = 0;
                    end
                end
            end
            S_DONE : begin
                if (core_o_valid[0] & core_o_valid[1]) begin
                    state_w = S_DOUT;
                    counter_w = 0;
                end
            end
            S_DOUT : begin
                output_valid_w = 1'b1;
                if (o_ready) begin
                    counter_w = counter_r + 1'b1;

                    if (counter_r == 2 * LOAD_CYCLE - 1) begin
                        state_w = S_IDLE;
                        output_valid_w = 1'b0;
                    end
                end
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_r        <= 3'd0;
            counter_r      <= 7'd0;
            key_r          <= 8'd0;
            input_ready_r  <= 1'b0;
            output_valid_r <= 1'b0;
            pos_result_r   <= 33'd0;
            neg_result_r   <= 33'd0;
        end else begin
            state_r        <= state_w;
            counter_r      <= counter_w;
            key_r          <= key_w;
            input_ready_r  <= input_ready_w;
            output_valid_r <= output_valid_w;
            pos_result_r   <= pos_result_w;
            neg_result_r   <= neg_result_w;
        end
    end

    FrFT_core #(
        .LOAD_CYCLE(LOAD_CYCLE), .MUL_CYCLE(MUL_CYCLE), .FNT_CYCLE(FNT_CYCLE),
        .DATA_WIDTH(DATA_WIDTH), .NZ_DATA_WIDTH(NZ_DATA_WIDTH),
        .REG_DEPTH(REG_DEPTH), .REG_ADDRW(REG_ADDRW),
        .REAL_SCALE(REAL_PATH1_SCALE), .IMAG_SCALE(IMAG_PATH1_SCALE)
    ) pos_core (
        .clk(clk), .rst_n(rst_n), .i_mode(1'b0),

        // control signals interface
        .i_valid(i_valid), .i_chirp3_ready(core_i_ready[0]),
        .o_ready(o_ready), .o_mul3_valid(core_o_valid[0]),

        // data interface
        .i_data(core_i_data),
        .i_chirp2_data(core_chirp2_data),
        .i_chirp3_data(core_chirp3_data),
        .o_data(pos_result_w)
    );

    FrFT_core #(
        .LOAD_CYCLE(LOAD_CYCLE), .MUL_CYCLE(MUL_CYCLE), .FNT_CYCLE(FNT_CYCLE),
        .DATA_WIDTH(DATA_WIDTH), .NZ_DATA_WIDTH(NZ_DATA_WIDTH),
        .REG_DEPTH(REG_DEPTH), .REG_ADDRW(REG_ADDRW),
        .REAL_SCALE(REAL_PATH2_SCALE), .IMAG_SCALE(IMAG_PATH2_SCALE)   
    ) neg_core (
        .clk(clk), .rst_n(rst_n), .i_mode(1'b1),

        // control signals interface
        .i_valid(i_valid), .i_chirp3_ready(core_i_ready[1]),
        .o_ready(o_ready), .o_mul3_valid(core_o_valid[1]),
        
        // data interface
        .i_data(core_i_data),
        .i_chirp2_data(core_chirp2_data),
        .i_chirp3_data(core_chirp3_data),
        .o_data(neg_result_w)
    );

    Chirp_Generator #(
        .REG_ADDRW(REG_ADDRW),
        .KEY_WIDTH(KEY_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) lut1 (
        .sel(lut_sel), // input 1 bit
        .idx(lut_idx), // input  REG_ADDRW  bits
        .key(key_r),   // input  KEY_WIDTH bits
        .out(lut_out)  // output LUT_WIDTH bits
    );

endmodule