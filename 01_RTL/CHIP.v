module CHIP #(
    // i_data[21:0] = {imag[10:0], real[10:0]} — 11+11 in/out path end-to-end
    parameter IOPORT_IN_W   = 11,
    parameter IOPORT_OUT_W  = 11,
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
    localparam O_IDLE   = 1'b0;
    localparam O_OUT    = 1'b1;

    reg [2:0] state_r, state_w;
    reg       o_state_r, o_state_w;
    reg [8:0] counter_r, counter_w;
    reg [5:0] o_counter_r, o_counter_w;
    reg [7:0] key_r, key_w;

    wire stage_sel;
    wire signed [16:0] mac_in_real, mac_in_imag;
    wire signed [16:0] pe_r0, pe_i0, pe_r1, pe_i1, pe_r2, pe_i2, pe_r3, pe_i3;

    // RegFiles
    reg rf_d_wen_1, rf_d_wen_2;
    reg   [4:0] rf_d_waddr_1, rf_d_waddr_2, rf_d_raddr_1;
    reg  [33:0] rf_d_wdata_1, rf_d_wdata_2;
    wire [33:0] rf_d_rdata_1;

    reg rf_io_wen_1, rf_io_wen_2;
    reg   [4:0] rf_io_waddr_1, rf_io_waddr_2, rf_io_raddr_1;
    reg  [21:0] rf_io_wdata_1, rf_io_wdata_2;
    wire [21:0] rf_io_rdata_1;

    // ==========================================
    // IO signals
    // ==========================================
    reg signed [10:0] real_hold_reg;
    assign i_ready = ((state_r == S_IDLE) || (state_r == S_LOAD));
    assign o_valid = (o_state_r == O_OUT);
    assign o_data = o_counter_r[0] ? rf_io_rdata_1[21:11] : rf_io_rdata_1[10:0];

    // Saturate 17-bit MAC/PE results to 11-bit RF storage (not truncate to 8)
    function automatic signed [10:0] sat11;
        input signed [16:0] v;
        begin
            if (v > $signed(17'sd1023))
                sat11 = 11'sd1023;
            else if (v < $signed(-17'sd1024))
                sat11 = -11'sd1024;
            else
                sat11 = v[10:0];
        end
    endfunction

    // ===================================================================
    // MAC control Signals
    // ===================================================================
    reg [5:0] n_cnt_d1;
    reg [2:0] g_cnt_d1, g_cnt_d2, g_cnt_d3;
    reg       pe_clear_d1, pe_done_d1, pe_done_d2;
    reg       mac_en, mac_valid_out_r;

    wire [4:0] current_n = counter_r[4:0];
    wire [2:0] current_g = counter_r[7:5];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            n_cnt_d1         <= 6'd0;
            g_cnt_d1         <= 3'd0;
            g_cnt_d2         <= 3'd0;
            g_cnt_d3         <= 3'd0;
            pe_clear_d1      <= 1'b0;
            pe_done_d1       <= 1'b0;
            pe_done_d2       <= 1'b0;
            mac_valid_out_r  <= 1'b0;
        end else if (mac_en) begin
            // [D1] 延遲一拍：SRAM 吐出資料，PE 開始算
            n_cnt_d1    <= {1'b0, current_n};
            g_cnt_d1    <= current_g;
            pe_clear_d1 <= (current_n == 5'd0);
            pe_done_d1  <= (current_n == 5'd31);

            // [D2] 延遲兩拍：acc_reg 準備好最終答案了！觸發 pe_done 讓 PE 更新 y_out
            g_cnt_d2    <= g_cnt_d1;
            pe_done_d2  <= pe_done_d1;

            // [D3] 延遲三拍：y_out 已經可以讀了！通知 CHIP 寫入 SRAM / 啟動 CORDIC
            g_cnt_d3    <= g_cnt_d2;
            mac_valid_out_r <= pe_done_d2;
        end else begin
            pe_clear_d1 <= 1'b0; pe_done_d1 <= 1'b0; pe_done_d2 <= 1'b0; mac_valid_out_r <= 1'b0;
        end
    end

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
            if (state_r == S_STAGE1 && mac_valid_out_r) begin
                c_state <= 1;
                c_start <= 1;
                c_group_idx <= g_cnt_d3;
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
            if (state_r == S_STAGE3 && mac_valid_out_r) begin
                rf_io_write_delay <= 1;
                delayed_mac_group <= g_cnt_d3;
                delayed_out2 <= {sat11(pe_i2), sat11(pe_r2)};
                delayed_out3 <= {sat11(pe_i3), sat11(pe_r3)};
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
            o_state_r   <= 0;
            counter_r   <= 0;
            o_counter_r <= 0;
            key_r       <= 0;
        end else begin
            state_r     <= state_w;
            o_state_r   <= o_state_w;
            counter_r   <= counter_w;
            o_counter_r <= o_counter_w;
            key_r       <= key_w;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)                 real_hold_reg <= 0;
        else if (state_r == S_LOAD) real_hold_reg <= i_data;
    end
    always @(*) begin
        state_w     = state_r;
        counter_w   = counter_r;
        o_counter_w = o_counter_r;
        key_w       = key_r;
        mac_en      = 1'b0;

        // ===================================================================
        // CORDIC 背景獨立寫入（保持你的完美設計）
        // ===================================================================
        rf_d_wen_1   = cordic_valid_out[0];
        rf_d_wen_2   = cordic_valid_out[1];
        rf_d_waddr_1 = c_idx_0; 
        rf_d_waddr_2 = c_idx_1;
        rf_d_wdata_1 = {cor_y_out[0], cor_x_out[0]};
        rf_d_wdata_2 = {cor_y_out[1], cor_x_out[1]};
        
        // 預設讀寫位址初始化，防止 Latch
        rf_d_raddr_1  = 0; 
        rf_io_wen_1   = 0; rf_io_wen_2   = 0;
        rf_io_raddr_1 = 0; 
        rf_io_waddr_1 = 0; rf_io_waddr_2 = 0;
        rf_io_wdata_1 = 0; rf_io_wdata_2 = 0;

        case(state_r)
            S_IDLE : begin
                if (i_valid) begin 
                    state_w   = S_LOAD;
                    counter_w = 0;
                    key_w     = i_data[7:0];
                end
            end
            S_LOAD : begin
                if (counter_r[0] == 1'b1) begin
                    rf_io_wen_1   = 1'b1;
                    rf_io_waddr_1 = counter_r[5:1];
                    rf_io_wdata_1 = {i_data, real_hold_reg};
                end
                counter_w = counter_r + 1;
                if (counter_r == 9'd63) begin
                    state_w = S_STAGE1;
                    counter_w = 9'd0;
                end
            end
            S_STAGE1 : begin
                mac_en = 1'b1;

                if (counter_r == 9'd258) begin
                    state_w    = S_STAGE3;
                    counter_w = 9'd0;
                end else begin
                    counter_w = counter_r + 1;
                end
            end
            S_STAGE3 : begin
                mac_en = 1'b1;
                rf_d_raddr_1 = current_n; 

                if (counter_r == 9'd256) begin
                    counter_w = counter_r;
                end else begin
                    counter_w = counter_r + 1;
                end

                if (mac_valid_out_r) begin
                    rf_io_wen_1   = 1; rf_io_wen_2 = 1;
                    rf_io_waddr_1 = {g_cnt_d3, 2'b00};
                    rf_io_waddr_2 = {g_cnt_d3, 2'b01};
                    rf_io_wdata_1 = {sat11(pe_i0), sat11(pe_r0)};
                    rf_io_wdata_2 = {sat11(pe_i1), sat11(pe_r1)};
                end else if (rf_io_write_delay) begin
                    rf_io_wen_1   = 1; rf_io_wen_2 = 1;
                    rf_io_waddr_1 = {delayed_mac_group, 2'b10};
                    rf_io_waddr_2 = {delayed_mac_group, 2'b11};
                    rf_io_wdata_1 = delayed_out2;
                    rf_io_wdata_2 = delayed_out3;
                end

                // 唯有最後一組 Delay 寫入徹底交卷，才准跨入 S_DONE
                if (rf_io_write_delay && delayed_mac_group == 3'd7) begin
                    state_w       = S_DONE;
                    counter_w     = 9'd0;
                    o_counter_w   = 0;
                end
            end
            S_DONE : begin
                state_w = S_IDLE;
            end
        endcase

        // ===================================================================
        // rf_io 的讀取位址多工器 (Multiplexer)
        // ===================================================================
        if (o_state_r == O_OUT) begin
            rf_io_raddr_1 = (o_counter_r + 1'b1) >> 1; // 輸出 FSM 佔用讀取埠
        end else if (state_r == S_DONE) begin
            rf_io_raddr_1 = 5'd0; // 為即將到來的 O_OUT 提前預取第 0 筆資料
        end else begin
            rf_io_raddr_1 = current_n; // Stage 1 與 Stage 3 佔用讀取埠
        end

        // ==========================================
        // Output FSM
        // ==========================================
        o_state_w = o_state_r;
        case(o_state_r)
            O_IDLE : begin
                o_counter_w = 6'd0;
                if (state_r == S_DONE) o_state_w = O_OUT;
            end
            O_OUT : begin
                if (o_ready) o_counter_w = o_counter_r + 1;
                if (o_counter_r == 6'd63) o_state_w = O_IDLE;
            end
        endcase
    end

    // ==========================================
    // Data Paths & Sub-Modules
    // ==========================================
    assign stage_sel = (state_r == S_STAGE3);

    wire signed [16:0] mac_in_real_s1 = {{6{rf_io_rdata_1[10]}}, rf_io_rdata_1[10:0]};
    wire signed [16:0] mac_in_imag_s1 = {{6{rf_io_rdata_1[21]}}, rf_io_rdata_1[21:11]};

    assign mac_in_real = (state_r == S_STAGE1) ? mac_in_real_s1 : rf_d_rdata_1[16:0];
    assign mac_in_imag = (state_r == S_STAGE1) ? mac_in_imag_s1 : rf_d_rdata_1[33:17];

    DFrFT_MAC mac(
        .clk(clk), .rst_n(rst_n), .en(mac_en), .stage_sel(stage_sel),
        .pe_clear(pe_clear_d1), .pe_done(pe_done_d2), .g_cnt(current_g), .n_cnt({1'b0, current_n}),
        .data_in_r(mac_in_real), .data_in_i(mac_in_imag),
        .y_out_0_r(pe_r0), .y_out_0_i(pe_i0), .y_out_1_r(pe_r1), .y_out_1_i(pe_i1),
        .y_out_2_r(pe_r2), .y_out_2_i(pe_i2), .y_out_3_r(pe_r3), .y_out_3_i(pe_i3)
    );

    RegFileDual #(.DATA_WIDTH(RF_DATA_W)) rf_data (
        .clk(clk), .rst_n(rst_n),
        .read_addr_1(rf_d_raddr_1),
        .read_data_1(rf_d_rdata_1),
        .wen1(rf_d_wen_1), .wen2(rf_d_wen_2),
        .write_addr_1(rf_d_waddr_1), .write_addr_2(rf_d_waddr_2),
        .write_data_1(rf_d_wdata_1), .write_data_2(rf_d_wdata_2)
    );

    RegFileDual #(.DATA_WIDTH(RF_IO_W)) rf_io (
        .clk(clk), .rst_n(rst_n),
        .read_addr_1(rf_io_raddr_1),
        .read_data_1(rf_io_rdata_1),
        .wen1(rf_io_wen_1), .wen2(rf_io_wen_2),
        .write_addr_1(rf_io_waddr_1), .write_addr_2(rf_io_waddr_2),
        .write_data_1(rf_io_wdata_1), .write_data_2(rf_io_wdata_2)
    );

endmodule