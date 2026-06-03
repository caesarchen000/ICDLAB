`timescale 1ns/10ps
`define CYCLE      10.0
`define MAX_CYCLE  2000
`define SDFFILE    "CHIP.sdf"

module tb;

    reg clk;
    reg rst_n;
    
    // ==========================================
    // 新版 I/O 介面宣告
    // ==========================================
    reg         i_valid;
    wire        i_ready;
    reg  [10:0] i_data;   // {imag[10:0], real[10:0]}
    
    reg         o_ready;
    wire        o_valid;
    wire [10:0] o_data;
    
    // Testbench 內部變數
    reg  [7:0]  key;

    // ==========================================
    // 實例化 CHIP (移除 key 腳位)
    // ==========================================
    CHIP u_chip (
        .clk(clk), 
        .rst_n(rst_n),
        .i_valid(i_valid), 
        .i_ready(i_ready),
        .o_ready(o_ready), 
        .o_valid(o_valid),
        .i_data(i_data), 
        .o_data(o_data)
    );

    // 記憶體與 Golden 測資
    reg [7:0]  mem_in_r  [0:31];
    reg [7:0]  mem_in_i  [0:31];
    reg [15:0] gold_hw_r [0:31];
    reg [15:0] gold_hw_i [0:31];
    reg [63:0] gold_th_r [0:31]; 
    reg [63:0] gold_th_i [0:31];

    integer i, fd_in, fd_gold, code;
    integer total_cycle = 0;

    // MSE 計算用的浮點數變數
    real th_r_real, th_i_real;
    real hw_r_real, hw_i_real;
    real err_r, err_i;
    real sq_err_r, sq_err_i;
    real total_mse_r, total_mse_i;
    integer hw_r_int, hw_i_int;

    function automatic signed [10:0] se11;
        input signed [7:0] v;
        se11 = {{3{v[7]}}, v};
    endfunction

    always begin
        #(`CYCLE/2) clk = ~clk;
    end

    always @(posedge clk) begin
        if (rst_n & ~i_valid & ~o_valid)
            total_cycle <= total_cycle + 1;
    end

    initial begin
        // =====================================
        // 1. 讀檔與初始化
        // =====================================
        fd_in   = $fopen("../00_TESTBED/pattern/input.txt", "r");
        fd_gold = $fopen("../00_TESTBED/pattern/golden.txt", "r");
        if (fd_in == 0 || fd_gold == 0) begin
            $display("Error: Cannot open files");
            $finish;
        end

        for (i = 0; i < 32; i = i + 1) begin
            code = $fscanf(fd_in, "%h %h\n", mem_in_r[i], mem_in_i[i]);
            code = $fscanf(fd_gold, "%h %h %h %h\n", gold_hw_r[i], gold_hw_i[i], gold_th_r[i], gold_th_i[i]);
        end
        $fclose(fd_in);
        $fclose(fd_gold);

        clk = 0; rst_n = 1; 
        i_valid = 0; i_data = 0; 
        o_ready = 0; key = 8'd64; 
        total_mse_r = 0.0; total_mse_i = 0.0;

        #15 rst_n = 0;
        #20 rst_n = 1;
        #10;

        // =====================================
        // 2. 輸入端：先送 Key，再送 32 筆 Data
        // =====================================
        @(negedge clk);
        
        // 【第一拍】: 送出 Key (CHIP 在 S_IDLE 時會抓取 i_data[7:0])
        i_valid = 1'b1;
        i_data  = {11'd0, {3'b0, key}};
        @(negedge clk);
        
        // 【接下來的 32 拍】: 連續送出 32 筆資料 (CHIP 在 S_LOAD 階段)
        for (i = 0; i < 32; i = i + 1) begin
            i_data  = se11(mem_in_r[i]);
            @(negedge clk);
            i_data  = se11(mem_in_i[i]);
            @(negedge clk);
        end
        i_valid = 1'b0; // 傳輸結束拉低 valid

        $display("\nProcessing DFrFT for Key = %d at cycle time = %2.1f", key, `CYCLE);
        $display("=======================================================================");
        $display("   Idx |  HW_R |    TH_R    | Err_R^2  ||  HW_I |    TH_I    | Err_I^2");
        $display("-----------------------------------------------------------------------");

        // =====================================
        // 3. 輸出端：連續接收 64 拍 (Real, Imag 交叉)
        // =====================================
        o_ready = 1'b1; // 告訴硬體 TB 端已經準備好接收

        wait(o_valid == 1'b1);

        @(negedge clk);
        for (i = 0; i < 32; i = i + 1) begin
            hw_r_int = $signed(o_data);
            @(negedge clk);
            hw_i_int = $signed(o_data);

            // 資料格式轉換為浮點數 real 並計算誤差
            hw_r_real = hw_r_int;
            hw_i_real = hw_i_int;
            th_r_real = $bitstoreal(gold_th_r[i]);
            th_i_real = $bitstoreal(gold_th_i[i]);

            err_r = hw_r_real - th_r_real;
            err_i = hw_i_real - th_i_real;
            sq_err_r = err_r * err_r;
            sq_err_i = err_i * err_i;

            total_mse_r = total_mse_r + sq_err_r;
            total_mse_i = total_mse_i + sq_err_i;

            // if ($signed(gold_hw_r[i]) !== hw_r_int || $signed(gold_hw_i[i]) !== hw_i_int) begin
            //     $display("❌ 抓到了！硬體算錯了 at Idx=%2d. HW_R=%4d, Python_R=%4d", 
            //               i, hw_r_int, $signed(gold_hw_r[i]));
            // end else begin
                $display("  %2d   | %5d | %10.4f | %8.4f || %5d | %10.4f | %8.4f", 
                        i, hw_r_int, th_r_real, sq_err_r, hw_i_int, th_i_real, sq_err_i);
            // end

            if (i != 31) @(negedge clk);
        end

        o_ready = 1'b0;

        // =====================================
        // 4. 結算最終 MSE 報告
        // =====================================
        total_mse_r = total_mse_r / 32.0;
        total_mse_i = total_mse_i / 32.0;

        $display("=======================================================================");
        $display("                   HARDWARE ERROR PERFORMANCE REPORT                   ");
        $display("=======================================================================");
        $display(" Real Channel MSE : %f", total_mse_r);
        $display(" Imag Channel MSE : %f", total_mse_i);
        $display(" Total MSE (R+I)  : %f", total_mse_r + total_mse_i);
        $display(" Total Exec cycle : %3d", total_cycle);
        $display("=======================================================================\n");
        $finish;
    end
    
    // VCD (no Verdi PLI): compile with +define+VCD
`ifdef VCD
    initial begin
        $dumpfile("CHIP_post.vcd");
        $dumpvars(0, tb);
    end
`endif

    // gate sim
    `ifdef SDF
        initial $sdf_annotate(`SDFFILE, u_chip);
    `endif

    // Timeout 防護機制
    initial begin
        #(`CYCLE * `MAX_CYCLE)
        $display("Time out");
        $finish;
    end
endmodule