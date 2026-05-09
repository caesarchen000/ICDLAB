module DFrFT_MAC (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               start_mac, 
    input  wire               stage_sel,
    input  wire signed [16:0]  data_in_r, 
    input  wire signed [16:0]  data_in_i, 
    
    output reg                valid_out, 
    output reg          [2:0] group_idx,
    output wire         [4:0] current_n,

    output wire signed [16:0] y_out_0_r, y_out_0_i,
    output wire signed [16:0] y_out_1_r, y_out_1_i,
    output wire signed [16:0] y_out_2_r, y_out_2_i,
    output wire signed [16:0] y_out_3_r, y_out_3_i
);
    integer i;
    reg [4:0] n_cnt;
    reg [2:0] g_cnt;
    reg is_computing;
    assign current_n = n_cnt;

    wire pe_clear   = (n_cnt == 5'd0);
    wire pe_done    = (n_cnt == 5'd31);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            n_cnt <= 5'd0;
            g_cnt <= 3'd0;
            is_computing <= 1'b0;
        end else begin
            if (start_mac) begin
                is_computing <= 1'b1;
                n_cnt <= 5'd0;
                g_cnt <= 3'd0;
            end else if (is_computing) begin
                n_cnt <= n_cnt + 1'b1;
                if (n_cnt == 5'd31) begin
                    if (g_cnt == 3'd7) is_computing <= 1'b0;
                    else               g_cnt <= g_cnt + 1'b1;
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            group_idx <= 3'd0;
        end else begin
            valid_out <= (is_computing && n_cnt == 5'd31);
            if (is_computing && n_cnt == 5'd31) group_idx <= g_cnt;
        end
    end

    wire [4:0] k_idx [0:3]; 
    assign k_idx[0] = {g_cnt, 2'b00};
    assign k_idx[1] = {g_cnt, 2'b01};
    assign k_idx[2] = {g_cnt, 2'b10};
    assign k_idx[3] = {g_cnt, 2'b11};

    reg [4:0] rom_n_idx [0:3], rom_k_idx [0:3];

    always @(*) begin
        for (i = 0; i <= 3; i = i + 1) begin
            rom_n_idx[i] = stage_sel ? k_idx[i] : n_cnt;
            rom_k_idx[i] = stage_sel ? n_cnt : k_idx[i];
        end
    end
    

    wire [1:0] s01, s02, s11, s12, s21, s22, s31, s32;
    wire [3:0] h01, h02, h11, h12, h21, h22, h31, h32;

    CSD_ROM_Table rom0 (.n_idx(rom_n_idx[0]), .k_idx(rom_k_idx[0]), .sign1(s01), .shift1(h01), .sign2(s02), .shift2(h02));
    CSD_ROM_Table rom1 (.n_idx(rom_n_idx[1]), .k_idx(rom_k_idx[1]), .sign1(s11), .shift1(h11), .sign2(s12), .shift2(h12));
    CSD_ROM_Table rom2 (.n_idx(rom_n_idx[2]), .k_idx(rom_k_idx[2]), .sign1(s21), .shift1(h21), .sign2(s22), .shift2(h22));
    CSD_ROM_Table rom3 (.n_idx(rom_n_idx[3]), .k_idx(rom_k_idx[3]), .sign1(s31), .shift1(h31), .sign2(s32), .shift2(h32));

    PE_Shift_Add pe0_r (
        .clk(clk), .rst_n(rst_n), .en(is_computing), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_r), .sign1(s01), .shf1(h01), .sign2(s02), .shf2(h02), .y_out(y_out_0_r)
        );
    PE_Shift_Add pe0_i (
        .clk(clk), .rst_n(rst_n), .en(is_computing), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_i), .sign1(s01), .shf1(h01), .sign2(s02), .shf2(h02), .y_out(y_out_0_i)
        );
    PE_Shift_Add pe1_r (
        .clk(clk), .rst_n(rst_n), .en(is_computing), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_r), .sign1(s11), .shf1(h11), .sign2(s12), .shf2(h12), .y_out(y_out_1_r)
        );
    PE_Shift_Add pe1_i (
        .clk(clk), .rst_n(rst_n), .en(is_computing), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_i), .sign1(s11), .shf1(h11), .sign2(s12), .shf2(h12), .y_out(y_out_1_i)
        );
    PE_Shift_Add pe2_r (
        .clk(clk), .rst_n(rst_n), .en(is_computing), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_r), .sign1(s21), .shf1(h21), .sign2(s22), .shf2(h22), .y_out(y_out_2_r)
        );
    PE_Shift_Add pe2_i (
        .clk(clk), .rst_n(rst_n), .en(is_computing), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_i), .sign1(s21), .shf1(h21), .sign2(s22), .shf2(h22), .y_out(y_out_2_i)
        );
    PE_Shift_Add pe3_r (
        .clk(clk), .rst_n(rst_n), .en(is_computing), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_r), .sign1(s31), .shf1(h31), .sign2(s32), .shf2(h32), .y_out(y_out_3_r)
        );
    PE_Shift_Add pe3_i (
        .clk(clk), .rst_n(rst_n), .en(is_computing), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_i), .sign1(s31), .shf1(h31), .sign2(s32), .shf2(h32), .y_out(y_out_3_i)
        );

endmodule