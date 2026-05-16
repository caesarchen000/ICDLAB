module DFrFT_MAC (
    input  wire               clk, rst_n,
    input  wire               en, stage_sel,
    input  wire               pe_clear, pe_done,            
    input  wire         [2:0] g_cnt,
    input  wire         [5:0] n_cnt,
    input  wire signed [16:0] data_in_r, 
    input  wire signed [16:0] data_in_i, 

    output wire signed [16:0] y_out_0_r, y_out_0_i,
    output wire signed [16:0] y_out_1_r, y_out_1_i,
    output wire signed [16:0] y_out_2_r, y_out_2_i,
    output wire signed [16:0] y_out_3_r, y_out_3_i
);
    integer i;

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
    
    wire [1:0] s01, s02, s03, s11, s12, s13, s21, s22, s23, s31, s32, s33;
    wire [3:0] h01, h02, h03, h11, h12, h13, h21, h22, h23, h31, h32, h33;

    ROM_Wrapper_Even rom0 (
        .clk(clk), .rst_n(rst_n), .en(en), .n_in(rom_n_idx[0]), .k_idx(rom_k_idx[0]),
        .reg_sign1(s01), .reg_shift1(h01), .reg_sign2(s02), .reg_shift2(h02), .reg_sign3(s03), .reg_shift3(h03)
    );
    ROM_Wrapper_Odd  rom1 (
        .clk(clk), .rst_n(rst_n), .en(en), .n_in(rom_n_idx[1]), .k_idx(rom_k_idx[1]),
        .reg_sign1(s11), .reg_shift1(h11), .reg_sign2(s12), .reg_shift2(h12), .reg_sign3(s13), .reg_shift3(h13)
    );
    ROM_Wrapper_Even rom2 (
        .clk(clk), .rst_n(rst_n), .en(en), .n_in(rom_n_idx[2]), .k_idx(rom_k_idx[2]),
        .reg_sign1(s21), .reg_shift1(h21), .reg_sign2(s22), .reg_shift2(h22), .reg_sign3(s23), .reg_shift3(h23)
    );
    ROM_Wrapper_Odd  rom3 (
        .clk(clk), .rst_n(rst_n), .en(en), .n_in(rom_n_idx[3]), .k_idx(rom_k_idx[3]),
        .reg_sign1(s31), .reg_shift1(h31), .reg_sign2(s32), .reg_shift2(h32), .reg_sign3(s33), .reg_shift3(h33)
    );

    PE_Shift_Add pe0_r (
        .clk(clk), .rst_n(rst_n), .en(en), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_r), .sign1(s01), .shf1(h01), .sign2(s02), .shf2(h02), .sign3(s03), .shf3(h03),
        .y_out(y_out_0_r)
        );
    PE_Shift_Add pe0_i (
        .clk(clk), .rst_n(rst_n), .en(en), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_i), .sign1(s01), .shf1(h01), .sign2(s02), .shf2(h02), .sign3(s03), .shf3(h03),
        .y_out(y_out_0_i)
        );
    PE_Shift_Add pe1_r (
        .clk(clk), .rst_n(rst_n), .en(en), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_r), .sign1(s11), .shf1(h11), .sign2(s12), .shf2(h12), .sign3(s13), .shf3(h13),
        .y_out(y_out_1_r)
        );
    PE_Shift_Add pe1_i (
        .clk(clk), .rst_n(rst_n), .en(en), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_i), .sign1(s11), .shf1(h11), .sign2(s12), .shf2(h12), .sign3(s13), .shf3(h13),
        .y_out(y_out_1_i)
        );
    PE_Shift_Add pe2_r (
        .clk(clk), .rst_n(rst_n), .en(en), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_r), .sign1(s21), .shf1(h21), .sign2(s22), .shf2(h22), .sign3(s23), .shf3(h23),
        .y_out(y_out_2_r)
        );
    PE_Shift_Add pe2_i (
        .clk(clk), .rst_n(rst_n), .en(en), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_i), .sign1(s21), .shf1(h21), .sign2(s22), .shf2(h22), .sign3(s23), .shf3(h23),
        .y_out(y_out_2_i)
        );
    PE_Shift_Add pe3_r (
        .clk(clk), .rst_n(rst_n), .en(en), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_r), .sign1(s31), .shf1(h31), .sign2(s32), .shf2(h32), .sign3(s33), .shf3(h33),
        .y_out(y_out_3_r)
        );
    PE_Shift_Add pe3_i (
        .clk(clk), .rst_n(rst_n), .en(en), .clear(pe_clear), .calc_done(pe_done), .stage_sel(stage_sel),
        .x_in(data_in_i), .sign1(s31), .shf1(h31), .sign2(s32), .shf2(h32), .sign3(s33), .shf3(h33),
        .y_out(y_out_3_i)
        );

endmodule