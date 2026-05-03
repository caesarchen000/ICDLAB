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
*     2026.05.03    Guan-Yi Tsen
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
    // state parameter for main FSM
    localparam S_IDLE = 3'd0; // wait for i_ready to load key
    localparam S_LOAD = 3'd1; // load input data
    localparam S_LCH1 = 3'd2; // load chirp 1 signal
    localparam S_LCH2 = 3'd3; // load chirp 2 signal
    localparam S_LCH3 = 3'd4; // load chirp 3 signal
    localparam S_DONE = 3'd5; // assert o_valid, wait for o_ready to output preamble

    // state parameter for output FSM
    localparam OUT_IDLE = 1'b0;
    localparam OUT_BUSY = 1'b1; // data out

    // constant for scaling in final decode stage
    parameter REAL_PATH1_SCALE = 33'h0_fc00_0000;
    parameter IMAG_PATH1_SCALE = 33'h0_ffff_fc00;
    parameter REAL_PATH2_SCALE = 33'h0_fc00_0000;
    parameter IMAG_PATH2_SCALE = 33'h0_0000_03ff;

    // counter & state signal declaration
    reg             [6:0] counter_r, counter_w, out_counter_r, out_counter_w;
    reg             [3:0] state_r, state_w;
    reg                   out_state_r, out_state_w;

    // key register
    reg   [KEY_WIDTH-1:0] key_r, key_w;

    // LUT signals
    reg                   lut_sel;
    reg   [REG_ADDRW-2:0] lut_idx;
    wire  [LUT_WIDTH-1:0] lut_out; // {8'imag, 8'real}

    // Core interface signals
    wire  [1:0] core_i_chirp_ready, core_o_valid;
    reg  [32:0] core_i_data [0:1];
    wire [32:0] core_path1_chirp13_data_0, core_path1_chirp13_data_1;
    wire [32:0] core_path2_chirp13_data_0, core_path2_chirp13_data_1;
    wire [32:0] core_path1_chirp2_data_0, core_path1_chirp2_data_1;
    wire [32:0] core_path2_chirp2_data_0, core_path2_chirp2_data_1;
    reg  [32:0] pos_result_r, neg_result_r;
    wire [32:0] pos_result_w, neg_result_w;

    // ====================================================================
    // IO interface
    // ====================================================================
    reg input_ready_r, input_ready_w, output_valid_r, output_valid_w;
    assign i_ready = input_ready_r;
    assign o_valid = output_valid_r;

    wire signed [33:0] decoded_pos = decode_dim1(pos_result_r);
    wire signed [33:0] decoded_neg = decode_dim1(neg_result_r);
    wire signed [34:0] final_sum = decoded_pos + decoded_neg;
    assign o_data  = final_sum[28:17]; // 17 bit with scale = 64*32*64

    // ====================================================================
    // Decode from Fermat ring (dim-1) into signed integer
    // ====================================================================
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
    // Transform 16-bit input into fermat ring
    // ====================================================================
    function [32:0] input_transformation;
        input [15:0] data; // data[15:8] = Imag(Y), data[7:0] = Real(X)
        input        mode; // 0: Path 1 (X + jY), 1: Path 2 (X - jY)
        
        // 宣告 35-bit 以確保在加減法過程中絕對不會發生 Overflow 或 Underflow
        localparam signed [34:0] FQ = 35'h1_0000_0001; // 2^32 + 1
        
        reg signed [34:0] real_ext;
        reg signed [34:0] imag_shifted;
        reg signed [34:0] val_signed;
        reg        [33:0] val_mod;
        
        begin 
            // 1. 符號擴充 (Sign Extension)
            // X: 8-bit 有號數，向高位補 27 個符號位以達到 35-bit
            real_ext = {{27{data[7]}}, data[7:0]};
            
            // Y: 8-bit 有號數，先向高位補 11 個符號位，再向左 shift 16-bit
            imag_shifted = {{11{data[15]}}, data[15:8], 16'd0};
            
            // 2. 平行路徑加減法
            if (mode == 1'b0) begin
                val_signed = real_ext + imag_shifted; // Path 1
            end else begin
                val_signed = real_ext - imag_shifted; // Path 2
            end
            
            // 3. 模數修正 (Modulo Correction)
            // 在有限環中，負數 -K 等同於 FQ - K。所以若小於 0，直接加上 FQ
            if (val_signed < 0) begin
                val_mod = val_signed + FQ;
            end else begin
                val_mod = val_signed[33:0];
            end
            
            // 4. 轉換為 Diminished-1 格式
            input_transformation = (val_mod == 34'd0) ? 
                                   33'h1_0000_0000 : 
                                   {1'b0, val_mod[31:0] - 32'd1};
        end
    endfunction

    // ====================================================================
    // Main FSM
    // ====================================================================
    always @(*) begin
        key_w         = key_r;
        state_w       = state_r;
        counter_w     = counter_r;
        input_ready_w = input_ready_r;
        lut_sel = 0; lut_idx = 0;
        core_i_data[0] = 32'd0;
        core_i_data[1] = 32'd0;
        
        case(state_r)
            S_IDLE : begin
                if (out_state_r == OUT_IDLE)
                    input_ready_w  = 1'b1;

                if (i_valid) begin
                    state_w       = S_LOAD;
                    key_w         = i_data[KEY_WIDTH-1:0];
                    counter_w     = 0;
                    input_ready_w = 1'b0;
                end
            end
            S_LOAD : begin
                counter_w = counter_r + 1;
                core_i_data[0] = input_transformation(i_data, 1'b0);
                core_i_data[1] = input_transformation(i_data, 1'b1);
                
                if (counter_r == LOAD_CYCLE - 1) begin
                    state_w       = S_LCH1;
                    input_ready_w = 1'b0;
                    counter_w     = 0;
                end
            end
            S_LCH1 : begin
                lut_sel = 1'b0; // for chirp 1
                lut_idx = counter_r[3:0];
                
                if (&core_i_chirp_ready) begin
                    counter_w = counter_r + 1;
                    if (counter_r == MUL_CYCLE - 1) begin
                        state_w   = S_LCH2;
                        counter_w = 0;
                    end
                end
            end
            S_LCH2 : begin
                lut_sel = 1'b1; // for chirp2
                lut_idx = counter_r[3:0];

                if (&core_i_chirp_ready) begin
                    counter_w = counter_r + 1;
                    if (counter_r == MUL_CYCLE - 1) begin
                        state_w   = S_LCH3;
                        counter_w = 0;
                    end
                end
            end
            S_LCH3 : begin
                lut_sel = 1'b0; // for chirp3
                lut_idx = counter_r[3:0];

                if (&core_i_chirp_ready) begin
                    counter_w = counter_r + 1;
                    if (counter_r == MUL_CYCLE - 1) begin
                        state_w   = S_DONE;
                        counter_w = 0;
                    end
                end
            end
            S_DONE : begin
                if (&core_o_valid) begin
                    state_w = S_IDLE;
                end
            end
        endcase
    end

    // ====================================================================
    // Output FSM
    // ====================================================================
    always @(*) begin
        out_state_w    = out_state_r;
        out_counter_w  = out_counter_r;
        output_valid_w = 1'b0;

        case(out_state_r)
            OUT_IDLE : begin
                if (state_r == S_DONE & (&core_o_valid)) begin
                    out_state_w   = OUT_BUSY;
                    out_counter_w = 0;
                end
            end
            OUT_BUSY : begin
                if (out_counter_r > 0) begin
                    output_valid_w = 1'b1;
                end

                if (o_ready || out_counter_r == 0) begin
                    out_counter_w = out_counter_r + 1'b1;

                    if (out_counter_r == 2 * LOAD_CYCLE) begin
                        out_state_w    = OUT_IDLE;
                        output_valid_w = 1'b0;
                    end
                end
            end
        endcase
    end

    // ====================================================================
    // Sequential logic
    // ====================================================================
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_r        <= 3'd0;
            out_state_r    <= 1'b0;
            counter_r      <= 7'd0;
            out_counter_r  <= 7'd0;
            key_r          <= 8'd0;
            input_ready_r  <= 1'b0;
            output_valid_r <= 1'b0;
            pos_result_r   <= 33'd0;
            neg_result_r   <= 33'd0;
        end else begin
            state_r        <= state_w;
            out_state_r    <= out_state_w;
            counter_r      <= counter_w;
            out_counter_r  <= out_counter_w;
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
        .clk(clk), .rst_n(rst_n),

        // control signals interface
        .i_valid(i_valid), .o_ready(o_ready),
        .i_chirp_ready(core_i_chirp_ready[0]), 
        .o_mul3_valid(core_o_valid[0]),

        // data interface
        .i_data(core_i_data[0]),
        .i_chirp13_data_0(core_path1_chirp13_data_0),
        .i_chirp13_data_1(core_path1_chirp13_data_1),
        .i_chirp2_data_0(core_path1_chirp2_data_0),
        .i_chirp2_data_1(core_path1_chirp2_data_1),
        .o_data(pos_result_w)
    );

    FrFT_core #(
        .LOAD_CYCLE(LOAD_CYCLE), .MUL_CYCLE(MUL_CYCLE), .FNT_CYCLE(FNT_CYCLE),
        .DATA_WIDTH(DATA_WIDTH), .NZ_DATA_WIDTH(NZ_DATA_WIDTH),
        .REG_DEPTH(REG_DEPTH), .REG_ADDRW(REG_ADDRW),
        .REAL_SCALE(REAL_PATH2_SCALE), .IMAG_SCALE(IMAG_PATH2_SCALE)   
    ) neg_core (
        .clk(clk), .rst_n(rst_n),

        // control signals interface
        .i_valid(i_valid), .o_ready(o_ready),
        .i_chirp_ready(core_i_chirp_ready[1]), 
        .o_mul3_valid(core_o_valid[1]),
        
        // data interface
        .i_data(core_i_data[1]),
        .i_chirp13_data_0(core_path2_chirp13_data_0),
        .i_chirp13_data_1(core_path2_chirp13_data_1),
        .i_chirp2_data_0(core_path2_chirp2_data_0),
        .i_chirp2_data_1(core_path2_chirp2_data_1),
        .o_data(neg_result_w)
    );

    Chirp_Generator_13 #(
        .REG_ADDRW(REG_ADDRW-1),
        .KEY_WIDTH(KEY_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) lut_gen1 (
        .idx(lut_idx), .key(key_r),  // inputREG_ADDRW, KEY_WIDTH bits
        // output DATA_WIDTH bits
        .path1_out0(core_path1_chirp13_data_0), .path1_out1(core_path1_chirp13_data_1),
        .path2_out0(core_path2_chirp13_data_0), .path2_out1(core_path2_chirp13_data_1)
    );

    Chirp_Generator_2 #(
        .REG_ADDRW(REG_ADDRW-1),
        .KEY_WIDTH(KEY_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) lut_gen2 (
        .idx(lut_idx), .key(key_r),  // inputREG_ADDRW, KEY_WIDTH bits
        // output DATA_WIDTH bits
        .path1_out0(core_path1_chirp2_data_0), .path1_out1(core_path1_chirp2_data_1),
        .path2_out0(core_path2_chirp2_data_0), .path2_out1(core_path2_chirp2_data_1)
    );

endmodule