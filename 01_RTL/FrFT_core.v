/********************************************************************
* Filename: FrFT_core.v
* Authors:
*     Guan-Yi Tsen
* Description:
*     Fractional Fourier Transform Core
* Parameters:
*     KEY_WIDTH    : input key width
*     INPUT_WIDTH  : input data width
*     OUTPUT_WIDTH : output data width
*     DATA_WIDTH   : internal calculation data width
*     REG_DEPTH    : how many words in reg file (N = ?)
*     REG_ADDRW    : reg data address width
*     MODULUS      : the choosen Fermat number 
* Note:
*
* Review History:
*     2026.04.18    Guan-Yi Tsen
*********************************************************************/

module FrFT #(
    parameter KEY_WIDTH    = 8,
    parameter IOPORT_IN_W  = 16, // 16-bit Input Pin
    parameter IOPORT_OUT_W = 8,  // 8-bit Output Pin
    parameter DATA_WIDTH   = 33, // 1-bit Flag + 32-bit Data
    parameter REG_DEPTH    = 32, // N = 32
    parameter REG_ADDRW    = $clog2(REG_DEPTH)
)(
    input                     clk,
    input                     rst_n, // asynchronous reset

    // input & output control signals
    input                     i_valid,
    output                    i_ready,
    input                     o_ready,
    output                    o_valid,

    // input & output data
    input                     i_mode, // 0 : 8-Real+8Imag, 1 : 32 bit data
    input   [IOPORT_IN_W-1:0] i_data,
    output [IOPORT_OUT_W-1:0] o_data
);
    // state parameter
    localparam S_IDLE = 4'd00; // wait for i_ready to load key
    localparam S_LPRE = 4'd01; // load preamble
    localparam S_LOAD = 4'd02; // load data
    localparam S_MUL1 = 4'd03; // i_data * chirp signal (sel=0)
    localparam S_FFNT = 4'd04; // Forward FNT
    localparam S_MUL2 = 4'd05; // pointwise multiplication with chirp signal (sel=1)
    localparam S_IFNT = 4'd06; // Inverse FNT
    localparam S_MUL3 = 4'd07; // result * chirp signal (sel=2)
    localparam S_NINV = 4'd08; // result * 16^-1 mod 65537
    localparam S_DONE = 4'd09; // assert o_valid, wait for o_ready to output preamble
    localparam S_DOUT = 4'd10; // start output data

    // control & state signal declaration
    reg             [3:0] state_r, state_w;
    reg             [6:0] counter_r, counter_w;
    reg                   input_ready_r, input_ready_w, output_valid_r, output_valid_w;
    reg                   mode_r, mode_w;
    reg   [KEY_WIDTH-1:0] key_r, key_w;
    reg   [REG_DEPTH-1:0] flag_r, flag_w; // store the preamble for 32 data
    reg [IOPORT_IN_W-1:0] tmp_load_r, tmp_load_w;

    // RegFile Signals
    reg   [REG_ADDRW-1:0] read_addr_1, read_addr_2, write_addr_1, write_addr_2;
    wire [DATA_WIDTH-1:0] read_data_1, read_data_2;
    reg  [DATA_WIDTH-1:0] write_data_1, write_data_2;
    reg                   reg_wen1, reg_wen2;

    // LUT signals
    reg                   lut_sel;
    reg   [REG_ADDRW-1:0] lut_idx;
    wire [DATA_WIDTH-1:0] lut_out;

    // Modular Multiplier signals
    reg  [DATA_WIDTH-1:0] mul_in_1, mul_in_2;
    wire [DATA_WIDTH-1:0] mul_out;

    // BFU signals
    reg             [4:0] bfu_shift;
    reg  [DATA_WIDTH-1:0] bfu_in_1, bfu_in_2;
    wire [DATA_WIDTH-1:0] bfu_add_out, bfu_sub_out;

    // ====================================================================
    // FNT Butterfly Address Generator (DIF)
    // ====================================================================
    wire [2:0] fnt_stage;
    wire [3:0] fnt_bfly;
    reg  [4:0] idxA, idxB, idxA_reverse, idxB_reverse;
    reg  [3:0] twiddle_k;
    assign {fnt_stage, fnt_bfly} = counter_r;

    always @(*) begin
        idxA = 0; idxB = 0; twiddle_k = 0;
        case(fnt_stage)
            3'd0 : twiddle_k = fnt_bfly;
            3'd1 : twiddle_k = {fnt_bfly[2:0], 1'b0};
            3'd2 : twiddle_k = {fnt_bfly[1:0], 2'b0};
            3'd3 : twiddle_k = {fnt_bfly[0], 3'b0};
            3'd4 : twiddle_k = 4'b0;
        endcase
        case(fnt_stage)
            3'd0 : begin
                idxA = {1'b0, fnt_bfly};
                idxB = {1'b1, fnt_bfly};
            end
            3'd1 : begin
                idxA = {fnt_bfly[3], 1'b0, fnt_bfly[2:0]};
                idxB = {fnt_bfly[3], 1'b1, fnt_bfly[2:0]};
            end
            3'd2 : begin
                idxA = {fnt_bfly[3:2], 1'b0, fnt_bfly[1:0]};
                idxB = {fnt_bfly[3:2], 1'b1, fnt_bfly[1:0]};
            end
            3'd3 : begin
                idxA = {fnt_bfly[3:1], 1'b0, fnt_bfly[0]};
                idxB = {fnt_bfly[3:1], 1'b1, fnt_bfly[0]};
            end
            3'd4 : begin
                idxA = {fnt_bfly, 1'b0};
                idxB = {fnt_bfly, 1'b1};
            end
        endcase
        idxA_reverse = {idxA[0], idxA[1], idxA[2], idxA[3], idxA[4]};
        idxB_reverse = {idxB[0], idxB[1], idxB[2], idxB[3], idxB[4]};
    end

    // ====================================================================
    // Mode Selection & Sign Extension Logic
    // ====================================================================
    wire [DATA_WIDTH-2:0] i_val_m0; // 32 bit
    wire [DATA_WIDTH-1:0] i_data_fermat; // 33 bit
    // For Mode 0 : 8-bit Real + 8-bit Imag
    assign i_val_m0 = {8'd0, i_data[15:8], 8'd0, i_data[7:0]};
    assign i_data_fermat = (i_val_m0 == 32'b0) ? 33'h1_0000_0000 : {1'b0, i_val_m0 - 1};

    // connect to IO
    wire     [DATA_WIDTH:0] true_out;
    reg  [IOPORT_OUT_W-1:0] o_data_reg;
    assign true_out = read_data_1[32] ? 34'd0 : {2'b0, read_data_1[31:0]};
    assign i_ready = input_ready_r;
    assign o_valid = output_valid_r;
    assign o_data = o_data_reg;

    always @(*) begin
        case(counter_r[1:0]) // 依序輸出 4 Bytes
            2'd0 : o_data_reg = (state_r == S_DONE) ? flag_r[31:24] : true_out[31:24];
            2'd1 : o_data_reg = (state_r == S_DONE) ? flag_r[23:16] : true_out[23:16];
            2'd2 : o_data_reg = (state_r == S_DONE) ? flag_r[15:8]  : true_out[15:8];
            2'd3 : o_data_reg = (state_r == S_DONE) ? flag_r[7:0]   : true_out[7:0];
        endcase
    end

    always @(*) begin
        key_w          = key_r;
        flag_w         = flag_r;
        mode_w         = mode_r;
        state_w        = state_r;
        counter_w      = counter_r;
        input_ready_w  = input_ready_r;
        output_valid_w = output_valid_r;
        tmp_load_w     = tmp_load_r;

        reg_wen1     = 0;  reg_wen2     = 0;
        read_addr_1  = 0;  read_addr_2  = 0;
        write_addr_1 = 0;  write_addr_2 = 0;
        write_data_1 = 0;  write_data_2 = 0;

        lut_sel   = 0; lut_idx  = 0;
        mul_in_1  = 0; mul_in_2 = 0;
        bfu_shift = 0; bfu_in_1 = 0; bfu_in_2 = 0;

        case(state_r)
            S_IDLE : begin
                input_ready_w  = 1'b1;
                output_valid_w = 1'b0;

                if (i_valid) begin
                    state_w    = S_LPRE;
                    key_w      = i_data[KEY_WIDTH-1:0];
                    mode_w     = i_mode;
                    counter_w  = 0;
                end
            end
            S_LPRE : begin
                input_ready_w  = 1'b1;
                if (i_valid) begin
                    flag_w = (counter_r == 0) ? {i_data, 16'b0} : {flag_r[31:16], i_data};
                    if (counter_r == 7'd1) begin
                        state_w       = S_LOAD;
                        counter_w     = 0;
                    end else begin
                        counter_w = counter_r + 1;
                    end
                end
            end
            S_LOAD : begin
                input_ready_w = 1'b1;
                if (i_valid) begin
                    read_addr_1   = counter_r[4:1];
                    counter_w     = counter_r + 1;
                    if (mode_r == 1'b0) begin
                        write_addr_1 = counter_r[4:0];
                        write_data_1 = i_data_fermat;
                        reg_wen1     = 1'b1;

                        if (counter_r == 7'd31) begin
                            state_w       = S_MUL1;
                            input_ready_w = 1'b0;
                            counter_w     = 0;
                        end
                    end else begin
                        if (counter_r[0] == 1'b0) begin
                            tmp_load_w = i_data;
                        end else begin
                            write_addr_1 = counter_r[5:1];
                            write_data_1 = {flag_r[counter_r[5:1]], tmp_load_r, i_data};
                            reg_wen1     = 1'b1;
                        end

                        if (counter_r == 7'd63) begin
                            state_w       = S_MUL1;
                            input_ready_w = 1'b0;
                            counter_w     = 0;
                        end
                    end
                end
            end
            S_MUL1 : begin
                read_addr_1  = counter_r[4:0];
                mul_in_1     = read_data_1;

                lut_sel      = 1'b0;
                lut_idx      = counter_r[4:0];
                mul_in_2     = lut_out;

                write_addr_1 = counter_r[4:0];
                write_data_1 = mul_out;
                reg_wen1     = 1'b1;

                if (counter_r == 7'd31) begin
                    state_w   = S_FFNT;
                    counter_w = 0;
                end else begin
                    counter_w = counter_r + 1;
                end
            end
            S_FFNT : begin
                read_addr_1  = idxA;
                read_addr_2  = idxB;

                bfu_in_1     = read_data_1;
                bfu_in_2     = read_data_2;
                bfu_shift    = twiddle_k;

                write_addr_1 = idxA;
                write_data_1 = bfu_add_out;
                write_addr_2 = idxB;
                write_data_2 = bfu_sub_out;

                reg_wen1     = 1'b1;
                reg_wen2     = 1'b1;

                if (counter_r == 7'd79) begin // 16 * 5 = 80
                    state_w   = S_MUL2;
                    counter_w = 0;
                end else begin
                    counter_w = counter_r + 1;
                end
            end
            S_MUL2 : begin
                read_addr_1  = counter_r[4:0];
                mul_in_1     = read_data_1;
                
                lut_sel      = 1'b1;
                lut_idx      = {counter_r[0], counter_r[1], counter_r[2], counter_r[3], counter_r[4]};
                mul_in_2     = lut_out;

                write_addr_1 = counter_r[4:0];
                write_data_1 = mul_out;
                reg_wen1     = 1'b1;

                if (counter_r == 7'd31) begin
                    state_w   = S_IFNT;
                    counter_w = 0;
                end else begin
                    counter_w = counter_r + 1;
                end
            end
            S_IFNT : begin
                read_addr_1 = idxA_reverse;
                read_addr_2 = idxB_reverse;

                if (twiddle_k == 0) begin
                    bfu_shift = 5'd0;
                    bfu_in_1  = read_data_1;
                    bfu_in_2  = read_data_2;
                end else begin
                    bfu_shift = 5'd16 - twiddle_k;
                    bfu_in_1  = read_data_2;
                    bfu_in_2  = read_data_1;
                end

                write_addr_1 = idxA_reverse;
                write_data_1 = bfu_add_out;
                write_addr_2 = idxB_reverse;
                write_data_2 = bfu_sub_out;
                reg_wen1     = 1'b1;
                reg_wen2     = 1'b1;

                if (counter_r == 7'd79) begin
                    state_w   = S_NINV;
                    counter_w = 0;
                end else begin
                    counter_w = counter_r + 1;
                end
            end
            S_NINV : begin
                read_addr_1  = counter_r[4:0];
                mul_in_1     = read_data_1;
                mul_in_2     = 33'h0_F800_0000;
                write_addr_1 = counter_r[4:0];
                write_data_1 = mul_out;
                reg_wen1     = 1'b1;

                if (counter_r == 7'd31) begin
                    state_w   = S_MUL3;
                    counter_w = 5'b0;
                end else begin
                    counter_w = counter_r + 1;
                end
            end
            S_MUL3 : begin
                read_addr_1 = counter_r[4:0];
                mul_in_1    = read_data_1;

                lut_sel     = 1'b0;
                lut_idx     = counter_r[4:0];
                mul_in_2    = lut_out;

                write_addr_1 = counter_r[4:0];
                write_data_1 = mul_out;
                reg_wen1     = 1'b1;

                flag_w[counter_r] = mul_out[32];

                if (counter_r == 7'd31) begin
                    state_w   = S_DONE;
                    counter_w = 0;
                end else begin
                    counter_w = counter_r + 1;
                end
            end
            S_DONE : begin
                output_valid_w = 1'b1;
                if (o_ready) begin
                    counter_w = counter_r + 1;
                    if (counter_r == 7'd3) begin
                        state_w   = S_DOUT;
                        counter_w = 5'b0;
                    end
                end
            end
            S_DOUT : begin
                output_valid_w = 1'b1;
                read_addr_1    = counter_r[6:2];

                if(o_ready) begin
                    if (counter_r == 7'd127) begin
                        state_w        = S_IDLE;
                        output_valid_w = 1'b0;
                    end else begin
                        counter_w = counter_r + 1;
                    end
                end
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_r        <= S_IDLE;
            input_ready_r  <= 1'b1;
            output_valid_r <= 1'b0;
            key_r          <= {KEY_WIDTH{1'b0}};
            flag_r         <= 32'b0;
            counter_r      <= 7'b0;
            mode_r         <= 1'b0;
            tmp_load_r     <= 32'b0;
        end else begin
            state_r        <= state_w;
            input_ready_r  <= input_ready_w;
            output_valid_r <= output_valid_w;
            key_r          <= key_w;
            flag_r         <= flag_w;
            counter_r      <= counter_w;
            mode_r         <= mode_w;
            tmp_load_r     <= tmp_load_w;
        end
    end

    // submodule declaration
    RegFile #(
        .DATA_WIDTH(DATA_WIDTH),
        .REG_DEPTH(REG_DEPTH),
        .REG_ADDRW(REG_ADDRW)
    ) regfile (
        .clk(clk),
        .read_addr_1(read_addr_1), .read_addr_2(read_addr_2), // input  REG_ADDRW  bits
        .read_data_1(read_data_1), .read_data_2(read_data_2), // output DATA_WIDTH bits
        .wen1(reg_wen1), .wen2(reg_wen2), // input 1 bit
        .write_addr_1(write_addr_1), .write_addr_2(write_addr_2), // input  REG_ADDRW bits
        .write_data_1(write_data_1), .write_data_2(write_data_2)  // output DATA_WIDTH bits
    );

    LUT_chirp #(
        .REG_ADDRW(REG_ADDRW),
        .KEY_WIDTH(KEY_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) lut1 (
        .sel(lut_sel), // input 1 bit
        .idx(lut_idx), // input  REG_ADDRW  bits
        .key(key_r),   // input  KEY_WIDTH bits
        .out(lut_out)  // output DATA_WIDTH bits
    );

    Dim1_Modular_Mul #(
        .DATA_WIDTH(DATA_WIDTH)
    ) mul (
        .clk(clk),
        .rst_n(rst_n),
        .A(mul_in_1), // input  DATA_WIDTH bits
        .B(mul_in_2), // input  DATA_WIDTH bits
        .O(mul_out)   // output DATA_WIDTH bits
    );

    Dim1_BFU #(  // pure combinational circuit
        .DATA_WIDTH(DATA_WIDTH)
    ) bfu (
        .k(bfu_shift),       // input  4 bits
        .A(bfu_in_1),        // input  DATA_WIDTH bits
        .B(bfu_in_2),        // input  DATA_WIDTH bits
        .O_add(bfu_add_out), // output DATA_WIDTH bits
        .O_sub(bfu_sub_out)  // output DATA_WIDTH bits
    );

endmodule