module PE_Shift_Add (
    input  wire               clk, rst_n, en, clear, calc_done, stage_sel,
    input  wire signed [16:0] x_in,
    input  wire [1:0]         sign1, sign2, sign3,
    input  wire [3:0]         shf1,  shf2,  shf3,
    output reg  signed [16:0] y_out
);
    wire signed [26:0] x_ext, term1_in, term2_in, term3_in;
    assign x_ext = {{10{x_in[16]}}, x_in};
    assign term1_in = (sign1[1]) ? 27'd0 : x_ext;
    assign term2_in = (sign2[1]) ? 27'd0 : x_ext;
    assign term3_in = (sign3[1]) ? 27'd0 : x_ext;
    
    // 移位運算 (只有在 sign[1] == 0 時，這裡的邏輯閘才會翻轉)
    wire signed [26:0] term1_shifted, term2_shifted, term3_shifted;
    assign term1_shifted = term1_in << shf1;
    assign term2_shifted = term2_in << shf2;
    assign term3_shifted = term3_in << shf3;
    
    // 決定加或減：sign[1] 已經保證 0 輸出，這裡只需看 sign[0] 決定正負
    // sign[0] == 0 -> 加法, sign[0] == 1 -> 減法
    wire signed [26:0] term1, term2, term3;
    assign term1 = (sign1[0]) ? -term1_shifted : term1_shifted;
    assign term2 = (sign2[0]) ? -term2_shifted : term2_shifted;
    assign term3 = (sign3[0]) ? -term3_shifted : term3_shifted;

    wire [4:0] shf_amt;
    wire signed [26:0] rnd_const;
    assign shf_amt   = stage_sel ? 5'd14 : 5'd10;
    assign rnd_const = stage_sel ? 27'sd8192 : 27'sd512;

    wire signed [26:0] base_val, next_acc;
    reg signed [26:0] acc_reg;
    assign base_val = clear ? rnd_const : acc_reg;
    assign next_acc = base_val + term1 + term2 + term3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) acc_reg <= 27'd0;
        else        acc_reg <= next_acc;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) y_out <= 17'd0;
        else if (en && calc_done) y_out <= acc_reg >>> shf_amt;
    end
endmodule