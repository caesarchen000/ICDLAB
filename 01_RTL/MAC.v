module DFrFT_MAC (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               start_mac, 
    input  wire               stage_sel,
    input  wire signed [16:0]  data_in_r, 
    input  wire signed [16:0]  data_in_i, 
    
    output reg                valid_out, 
    output reg  [3:0]         group_idx,
    output wire [4:0]         current_n,

    output wire signed [16:0] y_out_0_r,
    output wire signed [16:0] y_out_0_i,
    output wire signed [16:0] y_out_1_r,
    output wire signed [16:0] y_out_1_i 
);

    reg [4:0] n_cnt;
    reg [3:0] g_cnt;
    reg is_computing;
    assign current_n = n_cnt;

    wire pe_clear   = (n_cnt == 5'd0);
    wire pe_done    = (n_cnt == 5'd31);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            n_cnt <= 5'd0;
            g_cnt <= 4'd0;
            is_computing <= 1'b0;
        end else begin
            if (start_mac) begin
                is_computing <= 1'b1;
                n_cnt <= 5'd0;
                g_cnt <= 4'd0;
            end else if (is_computing) begin
                n_cnt <= n_cnt + 1'b1;
                if (n_cnt == 5'd31) begin
                    if (g_cnt == 4'd15) is_computing <= 1'b0;
                    else                g_cnt <= g_cnt + 1'b1;
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            group_idx <= 4'd0;
        end else begin
            valid_out <= (is_computing && n_cnt == 5'd31);
            if (is_computing && n_cnt == 5'd31) group_idx <= g_cnt;
        end
    end

    wire [4:0] k_idx_0 = {g_cnt, 1'b0};
    wire [4:0] k_idx_1 = {g_cnt, 1'b1};

    // [重大修正] 根據 Stage_sel 動態 Swap (轉置) 矩陣查表方向
    wire [4:0] rom0_n_idx = stage_sel ? k_idx_0 : n_cnt;
    wire [4:0] rom0_k_idx = stage_sel ? n_cnt : k_idx_0;
    
    wire [4:0] rom1_n_idx = stage_sel ? k_idx_1 : n_cnt;
    wire [4:0] rom1_k_idx = stage_sel ? n_cnt : k_idx_1;

    wire [1:0] sign_0_1, sign_0_2, sign_1_1, sign_1_2;
    wire [3:0] shf_0_1, shf_0_2, shf_1_1, shf_1_2;

    CSD_ROM_Table rom0 (
        .n_idx(rom0_n_idx), .k_idx(rom0_k_idx), 
        .sign1(sign_0_1), .shift1(shf_0_1), .sign2(sign_0_2), .shift2(shf_0_2)
    );

    CSD_ROM_Table rom1 (
        .n_idx(rom1_n_idx), .k_idx(rom1_k_idx), 
        .sign1(sign_1_1), .shift1(shf_1_1), .sign2(sign_1_2), .shift2(shf_1_2)
    );

    PE_Shift_Add pe0_real (
        .clk(clk), .rst_n(rst_n), .en(is_computing), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_r), .sign1(sign_0_1), .shf1(shf_0_1), .sign2(sign_0_2), .shf2(shf_0_2), .y_out(y_out_0_r)
    );
    
    PE_Shift_Add pe1_imag (
        .clk(clk), .rst_n(rst_n), .en(is_computing), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_i), .sign1(sign_0_1), .shf1(shf_0_1), .sign2(sign_0_2), .shf2(shf_0_2), .y_out(y_out_0_i)
    );

    PE_Shift_Add pe2_real (
        .clk(clk), .rst_n(rst_n), .en(is_computing), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_r), .sign1(sign_1_1), .shf1(shf_1_1), .sign2(sign_1_2), .shf2(shf_1_2), .y_out(y_out_1_r)
    );

    PE_Shift_Add pe3_imag (
        .clk(clk), .rst_n(rst_n), .en(is_computing), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_i), .sign1(sign_1_1), .shf1(shf_1_1), .sign2(sign_1_2), .shf2(shf_1_2), .y_out(y_out_1_i)
    );

endmodule