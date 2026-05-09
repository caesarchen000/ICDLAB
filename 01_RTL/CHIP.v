module CHIP #(
    parameter IOPORT_IN_W   = 16, // 16-bit Input Pin
    parameter IOPORT_OUT_W  = 11, // 11-bit Output Pin
    parameter RF_DATA_W     = 34,
    parameter RF_IO_W       = 22
)(
    input                     clk, rst_n,
    input                     i_valid,
    output                    i_ready,
    input                     o_ready,
    output                    o_valid,
    input   [IOPORT_IN_W-1:0] i_data,
    output [IOPORT_OUT_W-1:0] o_data
);
    localparam S_IDLE   = 3'd0;
    localparam S_LOAD   = 3'd1;
    localparam S_STAGE1 = 3'd2;
    localparam S_STAGE3 = 3'd3;
    localparam S_DONE   = 3'd4;
    localparam S_OUT    = 3'd5;

    reg [2:0] state_r, state_w;
    reg [4:0] counter_r, counter_w;
    reg [5:0] o_counter_r, o_counter_w;
    reg [7:0] key_r, key_w;

    wire mac_start_in, mac_valid_out, stage_sel;
    wire [2:0] mac_group_idx;
    wire [4:0] mac_current_n;
    wire signed [16:0] mac_in_real, mac_in_imag;
    wire signed [16:0] pe_r0, pe_i0, pe_r1, pe_i1, pe_r2, pe_i2, pe_r3, pe_i3;

    // RegFiles
    reg rf_d_wen_1, rf_d_wen_2;
    reg   [4:0] rf_d_waddr_1, rf_d_waddr_2, rf_d_raddr_1, rf_d_raddr_2;
    reg  [33:0] rf_d_wdata_1, rf_d_wdata_2;
    wire [33:0] rf_d_rdata_1, rf_d_rdata_2;

    reg rf_io_wen_1, rf_io_wen_2;
    reg   [4:0] rf_io_waddr_1, rf_io_waddr_2, rf_io_raddr_1, rf_io_raddr_2;
    reg  [21:0] rf_io_wdata_1, rf_io_wdata_2;
    wire [21:0] rf_io_rdata_1, rf_io_rdata_2;

    // ==========================================
    // IO signals
    // ==========================================
    assign i_ready = (state_r == S_IDLE) || (state_r == S_LOAD);
    assign o_valid = (state_r == S_DONE) || (state_r == S_OUT);
    assign o_data = o_counter_r[0] ? rf_io_rdata_1[21:11] : rf_io_rdata_1[10:0];

    // ==========================================
    // CORDIC data buffer
    // ==========================================
    reg [1:0] c_state;
    reg [2:0] c_group_idx;
    reg c_start;
    reg signed [16:0] c_buf_r [0:3];
    reg signed [16:0] c_buf_i [0:3];
    wire cordic_valid_out [0:1];
    wire signed [16:0] cor_x_out [0:1], cor_y_out [0:1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_state <= 0; c_start <= 0; c_group_idx <= 0;
        end else begin
            c_start <= 0; // Default off
            if (state_r == S_STAGE1 && mac_valid_out) begin
                c_state <= 1;
                c_start <= 1;
                c_group_idx <= mac_group_idx;
                c_buf_r[0] <= pe_r0; c_buf_i[0] <= pe_i0;
                c_buf_r[1] <= pe_r1; c_buf_i[1] <= pe_i1;
                c_buf_r[2] <= pe_r2; c_buf_i[2] <= pe_i2;
                c_buf_r[3] <= pe_r3; c_buf_i[3] <= pe_i3;
            end else if (c_state == 1 && cordic_valid_out[0]) begin
                c_state <= 2;
                c_start <= 1;
            end else if (c_state == 2 && cordic_valid_out[0]) begin
                c_state <= 0;
            end
        end
    end

    wire signed [16:0] c_in_r_0 = (c_state == 1) ? c_buf_r[0] : c_buf_r[2];
    wire signed [16:0] c_in_i_0 = (c_state == 1) ? c_buf_i[0] : c_buf_i[2];
    wire signed [16:0] c_in_r_1 = (c_state == 1) ? c_buf_r[1] : c_buf_r[3];
    wire signed [16:0] c_in_i_1 = (c_state == 1) ? c_buf_i[1] : c_buf_i[3];

    wire [4:0] c_idx_0 = (c_state == 1) ? {c_group_idx, 2'b00} : {c_group_idx, 2'b10};
    wire [4:0] c_idx_1 = (c_state == 1) ? {c_group_idx, 2'b01} : {c_group_idx, 2'b11};
    wire [5:0] k_ord_0 = {1'b0, c_idx_0};
    wire [5:0] k_ord_1 = (c_idx_1 == 5'd31) ? 6'd32 : {1'b0, c_idx_1};
    wire [15:0] phase_0 = -((key_r * k_ord_0) << 8);
    wire [15:0] phase_1 = -((key_r * k_ord_1) << 8);

    cordic_rotation cordic0(
        .clk(clk), .rst_n(rst_n), .valid_in(c_start),
        .x_in(c_in_r_0), .y_in(c_in_i_0), .phase_in(phase_0),
        .x_out(cor_x_out[0]), .y_out(cor_y_out[0]), .valid_out(cordic_valid_out[0])
    );
    cordic_rotation cordic1(
        .clk(clk), .rst_n(rst_n), .valid_in(c_start),
        .x_in(c_in_r_1), .y_in(c_in_i_1), .phase_in(phase_1),
        .x_out(cor_x_out[1]), .y_out(cor_y_out[1]), .valid_out(cordic_valid_out[1])
    );

    // ==========================================
    // Stage 3: IO Write Delay Buffer (4-to-2 寫入緩衝)
    // ==========================================
    reg rf_io_write_delay;
    reg [2:0] delayed_mac_group;
    reg [21:0] delayed_out2, delayed_out3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) rf_io_write_delay <= 0;
        else begin
            if (state_r == S_STAGE3 && mac_valid_out) begin
                rf_io_write_delay <= 1;
                delayed_mac_group <= mac_group_idx;
                delayed_out2 <= {pe_i2[10:0], pe_r2[10:0]};
                delayed_out3 <= {pe_i3[10:0], pe_r3[10:0]};
            end else begin
                rf_io_write_delay <= 0;
            end
        end
    end

    // ==========================================
    // Main FSM
    // ==========================================
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
                if (counter_r == 5'd31) state_w = S_STAGE1;
            end
            S_STAGE1 : begin
                // 當 MAC 算完最後一組，且 CORDIC 也乒乓算完最後一組時，才進入 Stage 3
                if (c_state == 2 && cordic_valid_out[0] && c_group_idx == 3'd7) begin
                    state_w = S_STAGE3;
                end
            end
            S_STAGE3 : begin
                // 等待 MAC 算完最後一組，且延遲的一拍 (Channel 2,3) 也寫入 IO SRAM 後結束
                if (rf_io_write_delay && delayed_mac_group == 3'd7) begin
                    state_w     = S_DONE;
                    o_counter_w = 0;
                end
            end
            S_DONE : begin
                if (o_ready) begin
                    o_counter_w = o_counter_r + 1;
                    state_w = S_OUT;
                end
            end
            S_OUT : begin
                o_counter_w = o_counter_r + 1;
                if (o_counter_r == 6'd63) state_w = S_IDLE;
            end
        endcase
    end

    // ==========================================
    // Data Paths & Sub-Modules
    // ==========================================
    assign stage_sel = (state_r == S_STAGE3);
    assign mac_start_in = (state_r == S_LOAD && state_w == S_STAGE1) || (state_r == S_STAGE1 && state_w == S_STAGE3);
    
    assign mac_in_real = (state_r == S_STAGE1) ? {{9{rf_io_rdata_1[7]}}, rf_io_rdata_1[7:0]} : rf_d_rdata_1[16:0];
    assign mac_in_imag = (state_r == S_STAGE1) ? {{9{rf_io_rdata_1[15]}}, rf_io_rdata_1[15:8]} : rf_d_rdata_1[33:17];

    DFrFT_MAC mac(
        .clk(clk), .rst_n(rst_n), .start_mac(mac_start_in), .stage_sel(stage_sel),
        .data_in_r(mac_in_real), .data_in_i(mac_in_imag),
        .valid_out(mac_valid_out), .group_idx(mac_group_idx), .current_n(mac_current_n),
        .y_out_0_r(pe_r0), .y_out_0_i(pe_i0), .y_out_1_r(pe_r1), .y_out_1_i(pe_i1),
        .y_out_2_r(pe_r2), .y_out_2_i(pe_i2), .y_out_3_r(pe_r3), .y_out_3_i(pe_i3)
    );

    RegFileDual #(.DATA_WIDTH(RF_DATA_W)) rf_data (
        .clk(clk), .rst_n(rst_n),
        .read_addr_1(rf_d_raddr_1), .read_addr_2(rf_d_raddr_2),
        .read_data_1(rf_d_rdata_1), .read_data_2(rf_d_rdata_2),
        .wen1(rf_d_wen_1), .wen2(rf_d_wen_2),
        .write_addr_1(rf_d_waddr_1), .write_addr_2(rf_d_waddr_2),
        .write_data_1(rf_d_wdata_1), .write_data_2(rf_d_wdata_2)
    );

    RegFileDual #(.DATA_WIDTH(RF_IO_W)) rf_io (
        .clk(clk), .rst_n(rst_n),
        .read_addr_1(rf_io_raddr_1), .read_addr_2(rf_io_raddr_2),
        .read_data_1(rf_io_rdata_1), .read_data_2(rf_io_rdata_2),
        .wen1(rf_io_wen_1), .wen2(rf_io_wen_2),
        .write_addr_1(rf_io_waddr_1), .write_addr_2(rf_io_waddr_2),
        .write_data_1(rf_io_wdata_1), .write_data_2(rf_io_wdata_2)
    );

    // ==========================================
    // SRAM R/W Controls
    // ==========================================
    always @(*) begin
        rf_d_wen_1   = 0; rf_d_wen_2   = 0;
        rf_d_raddr_1 = 0; rf_d_raddr_2 = 0;
        rf_d_waddr_1 = 0; rf_d_waddr_2 = 0;
        rf_d_wdata_1 = 0; rf_d_wdata_2 = 0;
        case (state_r)
            S_STAGE1 : begin
                rf_d_wen_1   = cordic_valid_out[0];
                rf_d_wen_2   = cordic_valid_out[1];
                rf_d_waddr_1 = c_idx_0;
                rf_d_waddr_2 = c_idx_1;
                rf_d_wdata_1 = {cor_y_out[0], cor_x_out[0]};
                rf_d_wdata_2 = {cor_y_out[1], cor_x_out[1]};
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
                if (mac_valid_out) begin
                    rf_io_wen_1 = 1; rf_io_wen_2 = 1;
                    rf_io_waddr_1 = {mac_group_idx, 2'b00};
                    rf_io_waddr_2 = {mac_group_idx, 2'b01};
                    rf_io_wdata_1 = {pe_i0[10:0], pe_r0[10:0]};
                    rf_io_wdata_2 = {pe_i1[10:0], pe_r1[10:0]};
                end else if (rf_io_write_delay) begin
                    rf_io_wen_1 = 1; rf_io_wen_2 = 1;
                    rf_io_waddr_1 = {delayed_mac_group, 2'b10};
                    rf_io_waddr_2 = {delayed_mac_group, 2'b11};
                    rf_io_wdata_1 = delayed_out2;
                    rf_io_wdata_2 = delayed_out3;
                end
            end
            S_OUT : begin
                rf_io_raddr_1 = o_counter_r[5:1];
            end
        endcase
    end
endmodule