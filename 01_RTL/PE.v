module PE_Shift_Add (
    input  wire               clk, rst_n, en, clear, calc_done, stage_sel,
    input  wire signed [16:0] x_in,
    input  wire [1:0]         sign1, // [修改] 2-bit
    input  wire [3:0]         shf1,
    input  wire [1:0]         sign2, // [修改] 2-bit
    input  wire [3:0]         shf2,
    output reg  signed [16:0] y_out
);

    wire signed [26:0] x_ext = {{10{x_in[16]}}, x_in};
    wire signed [26:0] term1_shifted = x_ext <<< shf1;
    wire signed [26:0] term2_shifted = x_ext <<< shf2;
    
    // [重大修正] 根據 2-bit 判斷：00=略過(補零), 01=加, 10=減
    wire signed [26:0] term1 = (sign1 == 2'b01) ? term1_shifted :
                               (sign1 == 2'b10) ? -term1_shifted : 27'd0;
    wire signed [26:0] term2 = (sign2 == 2'b01) ? term2_shifted :
                               (sign2 == 2'b10) ? -term2_shifted : 27'd0;
    
    wire signed [26:0] psum = term1 + term2;
    reg signed [26:0] acc_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) acc_reg <= 27'd0;
        else if (en) begin
            if (clear) acc_reg <= psum; 
            else       acc_reg <= acc_reg + psum; 
        end
    end

    wire signed [26:0] rnd_const = stage_sel ? 27'sd8192 : 27'sd512;
    wire [4:0]         shf_amt   = stage_sel ? 5'd14 : 5'd10;
    wire signed [26:0] total_sum = acc_reg + psum;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) y_out <= 17'd0;
        else if (en && calc_done) y_out <= (total_sum + rnd_const) >>> shf_amt;
    end
endmodule