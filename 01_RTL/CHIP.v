module CHIP #(
    parameter IOPORT_IN_W   = 16, // 16-bit Input Pin
    parameter IOPORT_OUT_W  = 11, // 11-bit Output Pin
    parameter RF_DATA_W     = 34,
    parameter RF_IO_W       = 22
)(
    input                     clk, rst_n,
    // input & output control signals
    input                     i_valid,
    output                    i_ready,
    input                     o_ready,
    output                    o_valid,
    
    // input & output data
    input   [IOPORT_IN_W-1:0] i_data,
    output [IOPORT_OUT_W-1:0] o_data
);
    localparam S_IDLE   = 3'd0;
    localparam S_LOAD   = 3'd1;
    localparam S_STAGE1 = 3'd2;
    localparam S_CORDIC = 3'd3;
    localparam S_STAGE3 = 3'd4;
    localparam S_OUT    = 3'd5;
    localparam S_DONE   = 3'd6;

    reg [2:0] state_r, state_w;
    reg [4:0] counter_r, counter_w;
    reg [5:0] o_counter_r, o_counter_w;
    reg [7:0] key_r, key_w;

    wire mac_valid_in, mac_valid_out, stage_sel;
    wire [3:0] mac_group_idx;
    wire [4:0] mac_current_n;
    wire signed [16:0] mac_in_real, mac_in_imag;
    wire signed [16:0] pe_out_0_real, pe_out_0_imag, pe_out_1_real, pe_out_1_imag;

    // data regfile 32 *34 bit
    reg rf_d_wen_1, rf_d_wen_2;
    reg   [4:0] rf_d_waddr_1, rf_d_waddr_2, rf_d_raddr_1, rf_d_raddr_2;
    reg  [33:0] rf_d_wdata_1, rf_d_wdata_2;
    wire [33:0] rf_d_rdata_1, rf_d_rdata_2;

    // IO regfile 32 *22 bit
    reg rf_io_wen_1, rf_io_wen_2;
    reg   [4:0] rf_io_waddr_1, rf_io_waddr_2, rf_io_raddr_1, rf_io_raddr_2;
    reg  [21:0] rf_io_wdata_1, rf_io_wdata_2;
    wire [21:0] rf_io_rdata_1, rf_io_rdata_2;

    // cordic interface
    reg [3:0] cordic_idx;
    reg [3:0] cordic_iter;
    reg  cordic_valid_in;
    wire cordic_valid_out [0:1];
    wire signed [16:0] cordic_x_out [0:1], cordic_y_out [0:1];
    wire signed [15:0] phase_in [0:1];

    // IO control signals
    assign i_ready = (state_r == S_LOAD);
    assign o_valid = (state_r == S_OUT);
    assign o_data = o_counter_r[0] ? rf_io_rdata_1[21:11] : rf_io_rdata_1[10:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_r     <= 0;
            counter_r   <= 0;
            o_counter_r <= 0;
            key_r       <= 0;
        end else begin
            state_r     <= state_w;
            counter_r   <= counter_w;
            o_counter_r <= o_counter_w;
            key_r       <= key_w;
        end
    end

    always @(*) begin
        state_w     = state_r;
        counter_w   = counter_r;
        o_counter_w = o_counter_r;
        key_w       = key_r;
        
        case(state_r)
            S_IDLE : begin
                if (i_valid) begin
                    state_w   = S_LOAD;
                    counter_w = 0;
                    key_w     = i_data[7:0];
                end
            end
            S_LOAD : begin
                counter_w = counter_r + 1;
                if (counter_r == 5'd31) begin
                    state_w = S_STAGE1;
                end
            end
            S_STAGE1 : begin
                if (mac_valid_out & mac_group_idx == 4'd15) begin
                    state_w = S_CORDIC;
                end
            end
            S_CORDIC : begin
                if (cordic_idx == 4'd15 & cordic_valid_out[0] & cordic_valid_out[1]) begin
                    state_w = S_STAGE3;
                end
            end
            S_STAGE3 : begin
                if (mac_valid_out & mac_group_idx == 4'd15) begin
                    state_w     = S_OUT;
                    o_counter_w = 0;
                end
            end
            S_OUT : begin
                if (o_ready) begin
                    o_counter_w = o_counter_r + 1;
                    if (o_counter_r == 6'd63) begin
                        state_w = S_DONE;
                    end
                end
            end
            S_DONE : begin
                state_w = S_IDLE;
            end
        endcase
    end

    // cordic
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cordic_idx      <= 0;
            cordic_iter     <= 0;
            cordic_valid_in <= 0;
        end else if (state_r == S_CORDIC) begin
            cordic_valid_in <= (cordic_iter == 4'd0);
            if (cordic_valid_out[0] & cordic_valid_out[1]) begin
                cordic_iter <= 0;
                cordic_idx  <= cordic_idx + 1;
            end else begin
                cordic_iter <= cordic_iter + 1;
            end
        end else begin
            cordic_idx  <= 0;
            cordic_iter <= 0;
        end
    end

    wire  [5:0] k_order_val [0:1];
    assign k_order_val[0] = {1'b0, cordic_idx, 1'b0};
    assign k_order_val[1] = (cordic_idx == 4'd15) ? 6'd32 : {1'b0, cordic_idx, 1'b1};
    assign phase_in[0] = - ((key_r * k_order_val[0]) << 8);
    assign phase_in[1] = - ((key_r * k_order_val[1]) << 8);

    assign stage_sel = (state_r == S_STAGE3);
    assign mac_in_real = (state_r == S_STAGE1) ? {{9{rf_io_rdata_1[7]}},  rf_io_rdata_1[7:0]}  : rf_d_rdata_1[16:0];
    assign mac_in_imag = (state_r == S_STAGE1) ? {{9{rf_io_rdata_1[15]}}, rf_io_rdata_1[15:8]} : rf_d_rdata_1[33:17];
    assign mac_valid_in = (state_r == S_LOAD & state_w == S_STAGE1) | (state_r == S_CORDIC & state_w == S_STAGE3);

    DFrFT_MAC mac(
        .clk(clk), .rst_n(rst_n),
        .start_mac(mac_valid_in), .stage_sel(stage_sel),
        .data_in_r(mac_in_real), .data_in_i(mac_in_imag),
        .valid_out(mac_valid_out), .group_idx(mac_group_idx), .current_n(mac_current_n),
        .y_out_0_r(pe_out_0_real), .y_out_0_i(pe_out_0_imag),
        .y_out_1_r(pe_out_1_real), .y_out_1_i(pe_out_1_imag)
    );

    cordic_rotation cordic0(
        .clk(clk), .rst_n(rst_n),
        .valid_in(cordic_valid_in),
        .x_in(rf_d_rdata_1[16:0]), .y_in(rf_d_rdata_1[33:17]),
        .phase_in(phase_in[0]),
        .x_out(cordic_x_out[0]), .y_out(cordic_y_out[0]),
        .valid_out(cordic_valid_out[0])
    );
    
    cordic_rotation cordic1(
        .clk(clk), .rst_n(rst_n),
        .valid_in(cordic_valid_in),
        .x_in(rf_d_rdata_2[16:0]), .y_in(rf_d_rdata_2[33:17]),
        .phase_in(phase_in[1]),
        .x_out(cordic_x_out[1]), .y_out(cordic_y_out[1]),
        .valid_out(cordic_valid_out[1])
    );

    RegFileDual #(
        .DATA_WIDTH(RF_DATA_W)
    ) rf_data (
        .clk(clk), .rst_n(rst_n),
        .read_addr_1(rf_d_raddr_1), .read_addr_2(rf_d_raddr_2),
        .read_data_1(rf_d_rdata_1), .read_data_2(rf_d_rdata_2),
        .wen1(rf_d_wen_1), .wen2(rf_d_wen_2),
        .write_addr_1(rf_d_waddr_1), .write_addr_2(rf_d_waddr_2),
        .write_data_1(rf_d_wdata_1), .write_data_2(rf_d_wdata_2)
    );

    RegFileDual #(
        .DATA_WIDTH(RF_IO_W)
    ) rf_io (
        .clk(clk), .rst_n(rst_n),
        .read_addr_1(rf_io_raddr_1), .read_addr_2(rf_io_raddr_2),
        .read_data_1(rf_io_rdata_1), .read_data_2(rf_io_rdata_2),
        .wen1(rf_io_wen_1), .wen2(rf_io_wen_2),
        .write_addr_1(rf_io_waddr_1), .write_addr_2(rf_io_waddr_2),
        .write_data_1(rf_io_wdata_1), .write_data_2(rf_io_wdata_2)
    );

    always @(*) begin
        rf_d_wen_1   = 0; rf_d_wen_2   = 0;
        rf_d_raddr_1 = 0; rf_d_raddr_2 = 0;
        rf_d_waddr_1 = 0; rf_d_waddr_2 = 0;
        rf_d_wdata_1 = 0; rf_d_wdata_2 = 0;

        case (state_r)
            S_STAGE1 : begin
                rf_d_wen_1   = mac_valid_out;
                rf_d_wen_2   = mac_valid_out;
                rf_d_waddr_1 = {mac_group_idx, 1'b0};
                rf_d_waddr_2 = {mac_group_idx, 1'b1};
                rf_d_wdata_1 = {pe_out_0_imag, pe_out_0_real};
                rf_d_wdata_2 = {pe_out_1_imag, pe_out_1_real};
            end
            S_CORDIC : begin
                rf_d_raddr_1 = {cordic_idx, 1'b0};
                rf_d_wen_1   = cordic_valid_out[0];
                rf_d_waddr_1 = {cordic_idx, 1'b0};
                rf_d_wdata_1 = {cordic_y_out[0], cordic_x_out[0]};

                rf_d_raddr_2 = {cordic_idx, 1'b1};
                rf_d_wen_2   = cordic_valid_out[1];
                rf_d_waddr_2 = {cordic_idx, 1'b1};
                rf_d_wdata_2 = {cordic_y_out[1], cordic_x_out[1]};
            end
            S_STAGE3 : begin
                rf_d_raddr_1 = mac_current_n;
            end
        endcase
    end

    always @(*) begin
        rf_io_wen_1   = 0; rf_io_wen_2   = 0;
        rf_io_raddr_1 = 0; rf_io_raddr_2 = 0;
        rf_io_waddr_1 = 0; rf_io_waddr_2 = 0;
        rf_io_wdata_1 = 0; rf_io_wdata_2 = 0;

        case (state_r)
            S_LOAD : begin
                rf_io_wen_1   = 1'b1;
                rf_io_waddr_1 = counter_r;
                rf_io_wdata_1 = i_data;
            end
            S_STAGE1 : begin
                rf_io_raddr_1 = mac_current_n;
            end
            S_STAGE3 : begin
                rf_io_wen_1   = mac_valid_out;
                rf_io_wen_2   = mac_valid_out;
                rf_io_waddr_1 = {mac_group_idx, 1'b0};
                rf_io_waddr_2 = {mac_group_idx, 1'b1};
                rf_io_wdata_1 = {pe_out_0_imag[10:0], pe_out_0_real[10:0]};
                rf_io_wdata_2 = {pe_out_1_imag[10:0], pe_out_1_real[10:0]};
            end
            S_OUT : begin
                rf_io_raddr_1 = o_counter_r[5:1];
            end
        endcase
    end
endmodule