module cordic_rotation #(
    parameter STAGES = 11,
    parameter OUTPUT_SHIFT = 5
)(
    input                    clk, rst_n,
    // control signal
    input                    valid_in,
    output reg               valid_out,
    // data input
    input      signed [16:0] x_in,     // y1_real
    input      signed [16:0] y_in,     // y1_imag
    input      signed [15:0] phase_in, // target rotation degree
    
    // data output
    output reg signed [16:0] x_out,  //  y2_real
    output reg signed [16:0] y_out   //  y2_imag
);

    // ==========================================
    // 1. CORDIC Atan Table
    // ==========================================
    wire signed [15:0] atan_table [0:10];
    assign atan_table[0]  = 16'd8192; assign atan_table[1]  = 16'd4836;
    assign atan_table[2]  = 16'd2555; assign atan_table[3]  = 16'd1297;
    assign atan_table[4]  = 16'd651;  assign atan_table[5]  = 16'd326;
    assign atan_table[6]  = 16'd163;  assign atan_table[7]  = 16'd81;
    assign atan_table[8]  = 16'd41;   assign atan_table[9]  = 16'd20;
    assign atan_table[10] = 16'd10;

    // ==========================================
    // 2. 內部狀態暫存器與計數器
    // ==========================================
    reg signed [17:0] x_reg, y_reg; // 為了防止內部溢位，多給 1 bit (18-bit)
    reg signed [15:0] z_reg;
    reg [3:0] step_cnt;             // 疊代計數器 (0 ~ 10)
    reg is_computing;

    // ==========================================
    // 3. FSM 與運算邏輯 (Datapath)
    // ==========================================
    // 判斷旋轉方向 (目標是讓 Z 趨近於 0)
    wire sign = z_reg[15]; 
    
    // 移位運算 (Shift)
    // wire signed [17:0] x_shift = x_reg >>> step_cnt;
    // wire signed [17:0] y_shift = y_reg >>> step_cnt;

    reg signed [16:0] x_shift, y_shift;
    always @(*) begin
        case(step_cnt)
            4'd0:  begin x_shift = x_reg;        y_shift = y_reg;        end
            4'd1:  begin x_shift = x_reg >>> 1;  y_shift = y_reg >>> 1;  end
            4'd2:  begin x_shift = x_reg >>> 2;  y_shift = y_reg >>> 2;  end
            4'd3:  begin x_shift = x_reg >>> 3;  y_shift = y_reg >>> 3;  end
            4'd4:  begin x_shift = x_reg >>> 4;  y_shift = y_reg >>> 4;  end
            4'd5:  begin x_shift = x_reg >>> 5;  y_shift = y_reg >>> 5;  end
            4'd6:  begin x_shift = x_reg >>> 6;  y_shift = y_reg >>> 6;  end
            4'd7:  begin x_shift = x_reg >>> 7;  y_shift = y_reg >>> 7;  end
            4'd8:  begin x_shift = x_reg >>> 8;  y_shift = y_reg >>> 8;  end
            4'd9:  begin x_shift = x_reg >>> 9;  y_shift = y_reg >>> 9;  end
            4'd10: begin x_shift = x_reg >>> 10; y_shift = y_reg >>> 10; end
            default: begin x_shift = 17'd0; y_shift = 17'd0; end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_reg <= 18'd0;
            y_reg <= 18'd0;
            z_reg <= 16'd0;
            step_cnt <= 4'd0;
            is_computing <= 1'b0;
            valid_out <= 1'b0;
            x_out <= 17'd0;
            y_out <= 17'd0;
        end else begin
            valid_out <= 1'b0; // 預設拉低

            if (valid_in && !is_computing) begin
                // [初始化載入]
                is_computing <= 1'b1;
                step_cnt <= 4'd0;
                
                // 處理輸入角度大於 90 度或小於 -90 度的情況 (Quadrant Mapping)
                // CORDIC 只能收斂 -90 ~ +90 度的旋轉
                if (phase_in > 16'sd16384 || phase_in < -16'sd16384) begin
                    x_reg <= -{x_in[16], x_in}; // 取負號並符號擴充
                    y_reg <= -{y_in[16], y_in};
                    z_reg <= (phase_in > 0) ? (phase_in - 16'd32768) : (phase_in + 16'd32768);
                end else begin
                    x_reg <= {x_in[16], x_in};
                    y_reg <= {y_in[16], y_in};
                    z_reg <= phase_in;
                end
                
            end else if (is_computing) begin
                // [疊代運算]
                if (!sign) begin 
                    x_reg <= x_reg - y_shift;
                    y_reg <= y_reg + x_shift;
                    z_reg <= z_reg - atan_table[step_cnt];
                end else begin   
                    x_reg <= x_reg + y_shift;
                    y_reg <= y_reg - x_shift;
                    z_reg <= z_reg + atan_table[step_cnt];
                end

                // 計數器控制
                if (step_cnt == STAGES) begin
                    is_computing <= 1'b0; // 算完 11 級，停機
                    valid_out <= 1'b1;
                    
                    // [輸出截斷]
                    // 根據 Python 的 `OUTPUT_SHIFT` 進行右移與截斷
                    // 注意：CORDIC 會產生約 1.6467 倍的 Gain，保留這個 Gain 讓後續 Stage 3 處理
                    x_out <= (x_reg + (18'sd1 << (OUTPUT_SHIFT - 1))) >>> OUTPUT_SHIFT;
                    y_out <= (y_reg + (18'sd1 << (OUTPUT_SHIFT - 1))) >>> OUTPUT_SHIFT;
                end else begin
                    step_cnt <= step_cnt + 1'b1;
                end
            end
        end
    end
endmodule