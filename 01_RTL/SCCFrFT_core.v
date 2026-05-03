/********************************************************************
* Filename: FrFT_core.v
* Authors:
*     Guan-Yi Tsen, Yu-Yan Zheng
* Description:
*     Fractional Fourier Transform Core
* Parameters:
*     LOAD_CYCLE    : cycle needs for load data / output data
*     MUL_CYCLE     : cycle needs for MUL (16 for 2*MOD_MUL)
*     FNT_CYCLE     : cycle needs for FNT and IFNT (40 for 2*BFU)
*     DATA_WIDTH    : internal calculation data width
*     NZ_DATA_WIDTH : data width without flag
*     LUT_WIDTH     : data width of lut output
*     REG_DEPTH     : how many words in reg file (N = ?)
*     REG_ADDRW     : reg data address width
* Note:
*
* Review History:
*     2026.05.03    Guan-Yi Tsen
*********************************************************************/

module FrFT_core #(
    parameter LOAD_CYCLE    = 7'd32,
    parameter MUL_CYCLE     = 7'd16,
    parameter FNT_CYCLE     = 7'd40,
    parameter DATA_WIDTH    = 33, // 1-bit flag + 32-bit Data
    parameter NZ_DATA_WIDTH = 32, // 32-bit non zero data (no flag)
    parameter LUT_WIDTH     = 16, 
    parameter REG_DEPTH     = 32, // N = 32
    parameter REG_ADDRW     = $clog2(REG_DEPTH),
    parameter REAL_SCALE    = 33'd0,
    parameter IMAG_SCALE    = 33'd0
)(
    input                           clk,
    input                           rst_n, // asynchronous reset

    // input & output control 
    input                           i_mode, // mode = 0 : path1, mode = 1 : path 2
    input                           i_valid,
    input                           o_ready,
    output reg                      i_data_ready,
    output reg                      i_chirp3_ready,
    output reg                      o_mul3_valid,

    // input & output data
    input       [NZ_DATA_WIDTH-1:0] i_data,        // chirp1 + input data concat
    input           [LUT_WIDTH-1:0] i_chirp2_data, // chirp 2 data to store in ChirpRegFile
    input           [LUT_WIDTH-1:0] i_chirp3_data, // {16'd0, imag, real}
    output reg     [DATA_WIDTH-1:0] o_data
);

    // state parameter for main FSM
    localparam S_IDLE = 4'd00; // wait for i_ready to load data
    localparam S_LDCP = 4'd01; // load chirp2 to chirp reg file
    localparam S_CFNT = 4'd02; // Apply FNT for chirp 2
    localparam S_LOAD = 4'd03; // load data
    localparam S_MUL1 = 4'd04; // i_data * chirp 1
    localparam S_FFNT = 4'd05; // Forward FNT
    localparam S_MUL2 = 4'd06; // pointwise multiplication with chirp 2
    localparam S_IFNT = 4'd07; // Inverse FNT
    localparam S_MUL3 = 4'd08; // result * chirp 3
    localparam S_DONE = 4'd09; // assert o_valid, wait for o_ready to output preamble

    // state parameter for output FSM
    localparam OUT_IDLE = 1'b0;
    localparam OUT_BUSY = 1'b1; // start output data 64 cycles

    // counter & state signal declaration
    reg                [6:0] counter_r, counter_w, out_counter_r, out_counter_w;
    reg                [3:0] state_r, state_w;
    reg                      out_state_r, out_state_w;

    // Data RegFile Signals (V)
    reg      [REG_ADDRW-1:0] read_addr_1,  read_addr_2,  read_addr_3,  read_addr_4;
    wire    [DATA_WIDTH-1:0] read_data_1,  read_data_2,  read_data_3,  read_data_4;
    reg      [REG_ADDRW-1:0] write_addr_1, write_addr_2, write_addr_3, write_addr_4;
    reg     [DATA_WIDTH-1:0] write_data_1, write_data_2, write_data_3, write_data_4;
    reg                      wen1, wen2, wen3, wen4;

    // Chirp RegFile Signals (V)
    reg      [REG_ADDRW-1:0] chirp_read_addr_1,  chirp_read_addr_2;
    wire    [DATA_WIDTH-1:0] chirp_read_data_1,  chirp_read_data_2;
    reg      [REG_ADDRW-1:0] chirp_write_addr_1, chirp_write_addr_2;
    reg     [DATA_WIDTH-1:0] chirp_write_data_1, chirp_write_data_2;
    reg                      chirp_wen1, chirp_wen2;

    // Modular Multiplier signals (V)
    reg     [DATA_WIDTH-1:0] mul_in_a_1, mul_in_b_1, mul_in_a_2, mul_in_b_2;
    wire    [DATA_WIDTH-1:0] mul_out_1, mul_out_2;

    // BFU signals (V)
    reg      [REG_ADDRW-1:0] bfu_shift_1, bfu_shift_2;
    reg     [DATA_WIDTH-1:0] bfu_in_a_1, bfu_in_b_1, bfu_in_a_2, bfu_in_b_2;
    wire    [DATA_WIDTH-1:0] bfu_add_out_1, bfu_sub_out_1, bfu_add_out_2, bfu_sub_out_2;

    // ====================================================================
    // MUL1 data type transformation (Signed 8-bit to Diminished-1)
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
    // FNT Butterfly Address Generator (Dual BFU Parallelization)
    // ====================================================================
    // 宣告兩組 BFU 需要的 Index 與 Twiddle
    reg [4:0] idxA_1, idxB_1, idxA_reverse_1, idxB_reverse_1;
    reg [4:0] idxA_2, idxB_2, idxA_reverse_2, idxB_reverse_2;
    reg [4:0] idxA_1_d1, idxB_1_d1;
    reg [4:0] idxA_2_d1, idxB_2_d1;
    reg [4:0] idxA_1_d2, idxB_1_d2, idxA_reverse_1_d2, idxB_reverse_1_d2;
    reg [4:0] idxA_2_d2, idxB_2_d2, idxA_reverse_2_d2, idxB_reverse_2_d2;
    reg [3:0] twiddle_k_1_d1, twiddle_k_2_d1;
    reg       dual_bfu_en;

    wire [2:0] fnt_stage;
    wire [3:0] fnt_bfly_1, fnt_bfly_2;

    // 假設你的 counter_r 在 FFNT/IFNT 狀態下，最低 3 位用作 bfly 計數，接下來 3 位用作 stage 計數
    assign fnt_stage  = dual_bfu_en ? counter_r[5:3] : counter_r[6:4];
    assign fnt_bfly_1 = dual_bfu_en ? {counter_r[2:0], 1'b0} : counter_r[3:0];
    assign fnt_bfly_2 = dual_bfu_en ? {counter_r[2:0], 1'b1} : 4'd0;

    always @(*) begin
        idxA_1 = 0; idxB_1 = 0;
        idxA_2 = 0; idxB_2 = 0;

        // ==========================================
        // BFU 1
        // ==========================================
        case(fnt_stage) // synopsys parallel_case
            3'd0 : begin
                idxA_1 = {1'b0, fnt_bfly_1};
                idxB_1 = {1'b1, fnt_bfly_1};
            end
            3'd1 : begin
                idxA_1 = {fnt_bfly_1[3], 1'b0, fnt_bfly_1[2:0]};
                idxB_1 = {fnt_bfly_1[3], 1'b1, fnt_bfly_1[2:0]};
            end
            3'd2 : begin 
                idxA_1 = {fnt_bfly_1[3:2], 1'b0, fnt_bfly_1[1:0]};
                idxB_1 = {fnt_bfly_1[3:2], 1'b1, fnt_bfly_1[1:0]};
            end
            3'd3 : begin
                idxA_1 = {fnt_bfly_1[3:1], 1'b0, fnt_bfly_1[0]};
                idxB_1 = {fnt_bfly_1[3:1], 1'b1, fnt_bfly_1[0]};
            end
            3'd4 : begin
                idxA_1 = {fnt_bfly_1, 1'b0};
                idxB_1 = {fnt_bfly_1, 1'b1};
            end
        endcase

        // ==========================================
        // BFU 2
        // ==========================================
        case(fnt_stage) // synopsys parallel_case
            3'd0 : begin
                idxA_2 = {1'b0, fnt_bfly_2};
                idxB_2 = {1'b1, fnt_bfly_2};
            end
            3'd1 : begin
                idxA_2 = {fnt_bfly_2[3], 1'b0, fnt_bfly_2[2:0]};
                idxB_2 = {fnt_bfly_2[3], 1'b1, fnt_bfly_2[2:0]};
            end
            3'd2 : begin
                idxA_2 = {fnt_bfly_2[3:2], 1'b0, fnt_bfly_2[1:0]};
                idxB_2 = {fnt_bfly_2[3:2], 1'b1, fnt_bfly_2[1:0]};
            end
            3'd3 : begin
                idxA_2 = {fnt_bfly_2[3:1], 1'b0, fnt_bfly_2[0]};
                idxB_2 = {fnt_bfly_2[3:1], 1'b1, fnt_bfly_2[0]};
            end
            3'd4 : begin
                idxA_2 = {fnt_bfly_2, 1'b0};
                idxB_2 = {fnt_bfly_2, 1'b1};
            end
        endcase

        // ==========================================
        // Bit reverse (for IFNT)
        // ==========================================
        idxA_reverse_1 = {idxA_1[0], idxA_1[1], idxA_1[2], idxA_1[3], idxA_1[4]};
        idxB_reverse_1 = {idxB_1[0], idxB_1[1], idxB_1[2], idxB_1[3], idxB_1[4]};
        idxA_reverse_2 = {idxA_2[0], idxA_2[1], idxA_2[2], idxA_2[3], idxA_2[4]};
        idxB_reverse_2 = {idxB_2[0], idxB_2[1], idxB_2[2], idxB_2[3], idxB_2[4]};

        idxA_reverse_1_d2 = {idxA_1_d2[0], idxA_1_d2[1], idxA_1_d2[2], idxA_1_d2[3], idxA_1_d2[4]};
        idxB_reverse_1_d2 = {idxB_1_d2[0], idxB_1_d2[1], idxB_1_d2[2], idxB_1_d2[3], idxB_1_d2[4]};
        idxA_reverse_2_d2 = {idxA_2_d2[0], idxA_2_d2[1], idxA_2_d2[2], idxA_2_d2[3], idxA_2_d2[4]};
        idxB_reverse_2_d2 = {idxB_2_d2[0], idxB_2_d2[1], idxB_2_d2[2], idxB_2_d2[3], idxB_2_d2[4]};
    end

    always @(posedge clk) begin
        idxA_1_d1 <= idxA_1;    idxB_1_d1 <= idxB_1;
        idxA_2_d1 <= idxA_2;    idxB_2_d1 <= idxB_2;
        idxA_1_d2 <= idxA_1_d1; idxB_1_d2 <= idxB_1_d1;
        idxA_2_d2 <= idxA_2_d1; idxB_2_d2 <= idxB_2_d1;

        case(fnt_stage) // synopsys parallel_case full_case
            3'd0 : twiddle_k_1_d1 <= fnt_bfly_1;
            3'd1 : twiddle_k_1_d1 <= {fnt_bfly_1[2:0], 1'b0};
            3'd2 : twiddle_k_1_d1 <= {fnt_bfly_1[1:0], 2'b0};
            3'd3 : twiddle_k_1_d1 <= {fnt_bfly_1[0], 3'b0};
            3'd4 : twiddle_k_1_d1 <= 4'b0;
        endcase

        case(fnt_stage) // synopsys parallel_case full_case
            3'd0 : twiddle_k_2_d1 <= fnt_bfly_2;
            3'd1 : twiddle_k_2_d1 <= {fnt_bfly_2[2:0], 1'b0};
            3'd2 : twiddle_k_2_d1 <= {fnt_bfly_2[1:0], 2'b0};
            3'd3 : twiddle_k_2_d1 <= {fnt_bfly_2[0], 3'b0};
            3'd4 : twiddle_k_2_d1 <= 4'b0;
        endcase
    end

    // ====================================================================
    // Main FSM
    // ====================================================================
    always @(*) begin
        state_w   = state_r;
        counter_w = counter_r;

        read_addr_1 = 0; write_addr_1 = 0; write_data_1 = 0; wen1 = 0;
        read_addr_2 = 0; write_addr_2 = 0; write_data_2 = 0; wen2 = 0;
        read_addr_3 = 0; write_addr_3 = 0; write_data_3 = 0; wen3 = 0;
        read_addr_4 = 0; write_addr_4 = 0; write_data_4 = 0; wen4 = 0;

        chirp_read_addr_1 = 0; chirp_write_addr_1 = 0; chirp_write_data_1 = 0; chirp_wen1 = 0;
        chirp_read_addr_2 = 0; chirp_write_addr_2 = 0; chirp_write_data_2 = 0; chirp_wen2 = 0;

        mul_in_a_1 = 0;  mul_in_b_1 = 0; mul_in_a_2 = 0; mul_in_b_2 = 0;
        bfu_shift_1 = 0; bfu_in_a_1 = 0; bfu_in_b_1 = 0;
        bfu_shift_2 = 0; bfu_in_a_2 = 0; bfu_in_b_2 = 0;
        dual_bfu_en = 1;
        o_data = 0; i_chirp3_ready = 0; o_mul3_valid = 0; i_data_ready = 0;

        case(state_r)
            S_IDLE : begin
                if (i_valid) begin
                    state_w   = S_LDCP;
                    counter_w = 0;
                end
            end
            S_LDCP : begin
                counter_w = counter_r + 1;

                chirp_write_addr_1 = counter_r[4:0];
                chirp_write_data_1 = input_transformation(i_chirp2_data, i_mode);
                chirp_wen1         = 1'b1;

                if (counter_r == LOAD_CYCLE - 1) begin
                    state_w   = S_CFNT;
                    counter_w = 0;
                end
            end
            S_CFNT : begin
                dual_bfu_en = 0;

                // delay 0 cycle
                chirp_read_addr_1 = idxA_1;
                chirp_read_addr_2 = idxB_1;

                // delay 1 cycle
                bfu_in_a_1  = chirp_read_data_1;
                bfu_in_b_1  = chirp_read_data_2;
                bfu_shift_1 = twiddle_k_1_d1;

                if (counter_r > 1) begin
                    // delay 2 cycle
                    chirp_wen1 = 1'b1; chirp_wen2 = 1'b1;
                    chirp_write_addr_1 = idxA_1_d2;
                    chirp_write_data_1 = bfu_add_out_1;
                    chirp_write_addr_2 = idxB_1_d2;
                    chirp_write_data_2 = bfu_sub_out_1;
                end

                if (counter_r == 2*FNT_CYCLE + 1) begin
                    state_w      = S_LOAD;
                    counter_w    = 0;
                    i_data_ready = 1'b1;
                end else begin
                    counter_w = counter_r + 1;
                end
            end
            S_LOAD : begin
                i_data_ready = 1'b1;

                if (i_valid) begin
                    counter_w = counter_r + 1;

                    write_addr_1 = counter_r[4:0];
                    write_data_1 = {1'b0, i_data};
                    wen1         = 1'b1;
                end
                if (counter_r == LOAD_CYCLE - 1) begin
                    state_w   = S_MUL1;
                    counter_w = 0;
                end
            end
            S_MUL1 : begin
                // delay 0 cycle
                read_addr_1 = {counter_r[3:0], 1'b0};
                read_addr_2 = {counter_r[3:0], 1'b1};

                // delay 1 cycle
                mul_in_a_1 = input_transformation(read_data_1[15:0],  i_mode);
                mul_in_b_1 = input_transformation(read_data_1[31:16], i_mode);
                mul_in_a_2 = input_transformation(read_data_2[15:0],  i_mode);
                mul_in_b_2 = input_transformation(read_data_2[31:16], i_mode);

                if (counter_r > 1) begin
                    // delay 2 cycle
                    wen1 = 1'b1; wen2 = 1'b1;
                    write_addr_1 = {(counter_r[3:0] - 4'd2), 1'b0};
                    write_data_1 = mul_out_1;

                    write_addr_2 = {(counter_r[3:0] - 4'd2), 1'b1};
                    write_data_2 = mul_out_2;
                end

                if (counter_r == MUL_CYCLE + 1) begin 
                    state_w   = S_FFNT;
                    counter_w = 0;
                end else begin
                    counter_w = counter_r + 1;
                end
            end
            S_FFNT : begin
                // delay 0 cycle
                read_addr_1 = idxA_1;
                read_addr_2 = idxB_1;
                read_addr_3 = idxA_2;
                read_addr_4 = idxB_2;

                // delay 1 cycle
                bfu_in_a_1  = read_data_1;
                bfu_in_b_1  = read_data_2;
                bfu_shift_1 = twiddle_k_1_d1;
                bfu_in_a_2  = read_data_3;
                bfu_in_b_2  = read_data_4;
                bfu_shift_2 = twiddle_k_2_d1;

                if (counter_r > 1) begin
                    // delay 2 cycle
                    wen1 = 1'b1; wen2 = 1'b1;
                    write_addr_1 = idxA_1_d2; write_data_1 = bfu_add_out_1;
                    write_addr_2 = idxB_1_d2; write_data_2 = bfu_sub_out_1;

                    wen3 = 1'b1; wen4 = 1'b1;
                    write_addr_3 = idxA_2_d2; write_data_3 = bfu_add_out_2;
                    write_addr_4 = idxB_2_d2; write_data_4 = bfu_sub_out_2;
                end

                if (counter_r == FNT_CYCLE + 1) begin
                    state_w   = S_MUL2;
                    counter_w = 0;
                end else begin
                    counter_w = counter_r + 1;
                end
            end
            S_MUL2 : begin
                // delay 0 cycle
                read_addr_1       = {counter_r[3:0], 1'b0};
                chirp_read_addr_1 = {counter_r[3:0], 1'b0};
                read_addr_2       = {counter_r[3:0], 1'b1};
                chirp_read_addr_2 = {counter_r[3:0], 1'b1};

                // delay 1 cycle
                mul_in_a_1 = read_data_1;
                mul_in_b_1 = chirp_read_data_1;
                mul_in_a_2 = read_data_2;
                mul_in_b_2 = chirp_read_data_2;

                if (counter_r > 1) begin
                    // delay 2 cycle
                    wen1 = 1'b1; wen2 = 1'b1;
                    write_addr_1 = {counter_r[3:0] - 4'd2, 1'b0};
                    write_data_1 = mul_out_1;
                    write_addr_2 = {counter_r[3:0] - 4'd2, 1'b1};
                    write_data_2 = mul_out_2;
                end

                if (counter_r == MUL_CYCLE + 1) begin
                    state_w   = S_IFNT;
                    counter_w = 0;
                end else begin
                    counter_w = counter_r + 1;
                end
            end
            S_IFNT : begin
                // delay 0 cycle
                read_addr_1 = idxA_reverse_1;
                read_addr_2 = idxB_reverse_1;
                read_addr_3 = idxA_reverse_2;
                read_addr_4 = idxB_reverse_2;

                // delay 1 cycle
                if (twiddle_k_1_d1 == 0) begin
                    bfu_shift_1 = 5'd0;
                    bfu_in_a_1  = read_data_1;
                    bfu_in_b_1  = read_data_2;
                end else begin
                    bfu_shift_1 = 5'd16 - twiddle_k_1_d1;
                    bfu_in_a_1  = read_data_2;
                    bfu_in_b_1  = read_data_1;
                end

                // twiddle_k_2_d1 will never be 0!
                bfu_shift_2 = 5'd16 - twiddle_k_2_d1;
                bfu_in_a_2  = read_data_4;
                bfu_in_b_2  = read_data_3;

                if (counter_r > 1) begin
                    // delay 2 cycle
                    wen1 = 1'b1; wen2 = 1'b1;
                    write_addr_1 = idxA_reverse_1_d2; write_data_1 = bfu_add_out_1;
                    write_addr_2 = idxB_reverse_1_d2; write_data_2 = bfu_sub_out_1;

                    wen3 = 1'b1; wen4 = 1'b1;
                    write_addr_3 = idxA_reverse_2_d2; write_data_3 = bfu_add_out_2;
                    write_addr_4 = idxB_reverse_2_d2; write_data_4 = bfu_sub_out_2;
                end

                if (counter_r < LOAD_CYCLE) begin
                    i_chirp3_ready     = 1;
                    chirp_wen1         = 1'b1;
                    chirp_write_addr_1 = counter_r;
                    chirp_write_data_1 = input_transformation(i_chirp3_data, i_mode);
                end

                if (counter_r == FNT_CYCLE + 1) begin
                    state_w   = S_MUL3;
                    counter_w = 0;
                end else begin
                    counter_w = counter_r + 1;
                end
            end
            S_MUL3 : begin
                // delay 0 cycle
                read_addr_1       = {counter_r[3:0], 1'b0};
                chirp_read_addr_1 = {counter_r[3:0], 1'b0};
                read_addr_2       = {counter_r[3:0], 1'b1};
                chirp_read_addr_2 = {counter_r[3:0], 1'b1};

                // delay 1 cycle
                mul_in_a_1 = read_data_1;
                mul_in_b_1 = chirp_read_data_1;
                mul_in_a_2 = read_data_2;
                mul_in_b_2 = chirp_read_data_2;

                if (counter_r > 1) begin
                    // delay 2 cycle
                    wen1 = 1'b1; wen2 = 1'b1;
                    write_addr_1 = {counter_r[3:0] - 4'd2, 1'b0};
                    write_data_1 = mul_out_1;
                    write_addr_2 = {counter_r[3:0] - 4'd2, 1'b1};
                    write_data_2 = mul_out_2;
                end

                if (counter_r == MUL_CYCLE + 1) begin
                    state_w   = S_DONE;
                    counter_w = 0;
                end else begin
                    counter_w = counter_r + 1;
                end
            end
            S_DONE : begin
                if (o_ready) begin
                    state_w = S_IDLE;
                    o_mul3_valid = 1;
                end
            end
        endcase

    // ====================================================================
    // Output FSM
    // ====================================================================
        out_state_w   = out_state_r;
        out_counter_w = out_counter_r;

        case(out_state_r)
            OUT_IDLE : begin
                if (state_r == S_DONE & o_ready) begin
                    out_state_w   = OUT_BUSY;
                    out_counter_w = 0;
                    read_addr_1   = 0;
                end
            end
            OUT_BUSY : begin
                if (out_counter_r < 2*LOAD_CYCLE) begin
                    // delay 0 cycle
                    read_addr_1 = (out_counter_r + 1) >> 1;
                    // delay 1 cycle
                    mul_in_a_1  = read_data_1;
                    mul_in_b_1  = out_counter_r[0] ? IMAG_SCALE : REAL_SCALE;
                end
                o_data = mul_out_1;

                if (out_counter_r == 2*LOAD_CYCLE) begin
                    out_state_w   = OUT_IDLE;
                end else begin
                    out_counter_w = out_counter_r + 1;
                end
            end
        endcase
    end

    // ====================================================================
    // Sequential logic
    // ====================================================================
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_r       <= S_IDLE;
            out_state_r   <= OUT_IDLE;
            counter_r     <= 0;
            out_counter_r <= 0;
        end else begin
            state_r       <= state_w;
            out_state_r   <= out_state_w;
            counter_r     <= counter_w;
            out_counter_r <= out_counter_w;
        end
    end

    // ====================================================================
    // Submodules declaration
    // ====================================================================

    RegFileTetra #(
        .DATA_WIDTH(DATA_WIDTH),
        .REG_DEPTH(REG_DEPTH),
        .REG_ADDRW(REG_ADDRW)
    ) RegFile (
        .clk(clk), .rst_n(rst_n),
        // read : input REG_ADDRW bits, output DATA_WIDTH bits
        .read_addr_1(read_addr_1), .read_data_1(read_data_1), 
        .read_addr_2(read_addr_2), .read_data_2(read_data_2),
        .read_addr_3(read_addr_3), .read_data_3(read_data_3),
        .read_addr_4(read_addr_4), .read_data_4(read_data_4),
        // write : input 1 bit, input REG_ADDRW bits, output DATA_WIDTH bits
        .wen1(wen1), .write_addr_1(write_addr_1), .write_data_1(write_data_1),
        .wen2(wen2), .write_addr_2(write_addr_2), .write_data_2(write_data_2),
        .wen3(wen3), .write_addr_3(write_addr_3), .write_data_3(write_data_3),
        .wen4(wen4), .write_addr_4(write_addr_4), .write_data_4(write_data_4)
    );

    RegFileDual #(
        .DATA_WIDTH(DATA_WIDTH),
        .REG_DEPTH(REG_DEPTH),
        .REG_ADDRW(REG_ADDRW)
    ) ChirpRegFile (
        .clk(clk), .rst_n(rst_n),
        // read : input REG_ADDRW bits, output DATA_WIDTH bits
        .read_addr_1(chirp_read_addr_1), .read_data_1(chirp_read_data_1), 
        .read_addr_2(chirp_read_addr_2), .read_data_2(chirp_read_data_2),
        // write : input 1 bit, input REG_ADDRW bits, output DATA_WIDTH bits
        .wen1(chirp_wen1), .write_addr_1(chirp_write_addr_1), .write_data_1(chirp_write_data_1),
        .wen2(chirp_wen2), .write_addr_2(chirp_write_addr_2), .write_data_2(chirp_write_data_2)
    );

    Dim1_Modular_Mul #( // delay 1 cycle
        .DATA_WIDTH(DATA_WIDTH)
    ) mul1 (
        .clk(clk),
        .A(mul_in_a_1), // input  DATA_WIDTH bits
        .B(mul_in_b_1), // input  DATA_WIDTH bits
        .O(mul_out_1)   // output DATA_WIDTH bits
    );

    Dim1_Modular_Mul #( // delay 1 cycle
        .DATA_WIDTH(DATA_WIDTH)
    ) mul2 (
        .clk(clk),
        .A(mul_in_a_2), // input  DATA_WIDTH bits
        .B(mul_in_b_2), // input  DATA_WIDTH bits
        .O(mul_out_2)   // output DATA_WIDTH bits
    );

    Dim1_BFU #(  // delay 1 cycle
        .DATA_WIDTH(DATA_WIDTH)
    ) bfu1 (
        .clk(clk),
        .k(bfu_shift_1),       // input  4 bits
        .A(bfu_in_a_1),        // input  DATA_WIDTH bits
        .B(bfu_in_b_1),        // input  DATA_WIDTH bits
        .O_add(bfu_add_out_1), // output DATA_WIDTH bits
        .O_sub(bfu_sub_out_1)  // output DATA_WIDTH bits
    );

    Dim1_BFU #(  // delay 1 cycle
        .DATA_WIDTH(DATA_WIDTH)
    ) bfu2 (
        .clk(clk),
        .k(bfu_shift_2),       // input  4 bits
        .A(bfu_in_a_2),        // input  DATA_WIDTH bits
        .B(bfu_in_b_2),        // input  DATA_WIDTH bits
        .O_add(bfu_add_out_2), // output DATA_WIDTH bits
        .O_sub(bfu_sub_out_2)  // output DATA_WIDTH bits
    );
endmodule