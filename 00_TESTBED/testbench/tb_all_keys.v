`timescale 1ns/10ps
`define CYCLE      20.0
`define MAX_CYCLE  2000
`define SDFFILE    "../02_SYN/Netlist/CHIP_syn.sdf"

module tb;

    reg clk;
    reg rst_n;
    
    // AXI-Stream 樣式訊號介面
    reg         i_valid;
    wire        i_ready;
    reg  [15:0] i_data;
    
    reg         o_ready;
    wire        o_valid;
    wire [10:0] o_data;
    
    reg  [7:0]  key;

    // 例化 CHIP
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
    
    // 全域 256 keys * 32 points = 8192
    reg [15:0] gold_hw_r [0:8191];
    reg [15:0] gold_hw_i [0:8191];
    reg [63:0] gold_th_r [0:8191];
    reg [63:0] gold_th_i [0:8191];

    integer i, fd_in, fd_gold, code;
    integer k_int, global_idx;
    integer total_cycle = 0;

    // MSE 計算用的浮點數變數
    real th_r_real, th_i_real;
    real hw_r_real, hw_i_real;
    real err_r, err_i;
    real sq_err_r, sq_err_i;
    real total_mse_r, total_mse_i;
    real key_mse_r, key_mse_i, key_mse_total;

    integer hw_r_int, hw_i_int;

    always begin
        #(`CYCLE/2) clk = ~clk;
    end

    always @(posedge clk) begin
        if (rst_n & o_ready)
            total_cycle <= total_cycle + 1;
    end

    initial begin
        // =====================================
        // 1. 讀檔與初始化
        // =====================================
        fd_in   = $fopen("../00_TESTBED/pattern/input_all_keys.txt", "r");
        fd_gold = $fopen("../00_TESTBED/pattern/golden_all_keys.txt", "r");
        
        if (fd_in == 0 || fd_gold == 0) begin
            $display("Error: Cannot open input.txt or golden_all_keys.txt");
            $finish;
        end

        // 讀取單一 Input
        for (i = 0; i < 32; i = i + 1) begin
            code = $fscanf(fd_in, "%h %h\n", mem_in_r[i], mem_in_i[i]);
        end
        $fclose(fd_in);

        // 讀取全域 Golden (8192 lines)
        for (i = 0; i < 8192; i = i + 1) begin
            code = $fscanf(fd_gold, "%h %h %h %h\n", gold_hw_r[i], gold_hw_i[i], gold_th_r[i], gold_th_i[i]);
        end
        $fclose(fd_gold);

        clk = 0; rst_n = 1; 
        i_valid = 0; i_data = 0; o_ready = 0; 
        total_mse_r = 0.0; total_mse_i = 0.0;

        #15 rst_n = 0;
        #20 rst_n = 1;
        #10;
        o_ready = 1'b1;
        $display("\n=======================================================================");
        $display("   STARTING GLOBAL SWEEP VERIFICATION (256 KEYS)");
        $display("=======================================================================");

        // =====================================
        // 2. 啟動 256 次連續驗證迴圈
        // =====================================
        for (k_int = -128; k_int <= 127; k_int = k_int + 1) begin
            key = k_int[7:0]; // 轉換為 8-bit unsigned/2's complement
            
            // [新增] 每次換 Key 時，將單一 Key 的 MSE 歸零
            key_mse_r = 0.0; key_mse_i = 0.0;

            if ((k_int + 128) % 32 == 0) 
                $display("Processing... %3d / 256 keys done.", k_int + 128);

            // --- A. 送入資料 ---
            wait(i_ready == 1'b1);
            @(negedge clk);
            
            i_valid = 1'b1;
            i_data  = {8'd0, key}; // 第一拍：送 Key
            @(negedge clk);
            
            for (i = 0; i < 32; i = i + 1) begin
                i_valid = 1'b1;
                i_data  = {mem_in_i[i], mem_in_r[i]}; // 32 拍：送 Data
                @(negedge clk);
            end
            i_valid = 1'b0;

            // --- B. 接收輸出並計算 MSE ---
            wait(o_valid == 1'b1);
            @(negedge clk);

            for (i = 0; i < 32; i = i + 1) begin
                // 計算在全域陣列中的絕對索引 (0 ~ 8191)
                global_idx = (k_int + 128) * 32 + i;

                // 第 1 拍：Real
                hw_r_int = $signed(o_data);
                @(negedge clk);
                
                // 第 2 拍：Imag
                hw_i_int = $signed(o_data);

                // 取出對應的理論浮點數
                hw_r_real = hw_r_int;
                hw_i_real = hw_i_int;
                th_r_real = $bitstoreal(gold_th_r[global_idx]);
                th_i_real = $bitstoreal(gold_th_i[global_idx]);

                // 比對硬體整數是否完全相符 (Bit-True Check)
                if ($signed(gold_hw_r[global_idx]) !== hw_r_int || 
                    $signed(gold_hw_i[global_idx]) !== hw_i_int) begin
                    $display("❌ FATAL BIT-TRUE ERROR at Key=%d, Idx=%d", k_int, i);
                    $display("   Expected : HW_R=%d, HW_I=%d", $signed(gold_hw_r[global_idx]), $signed(gold_hw_i[global_idx]));
                    $display("   Got      : HW_R=%d, HW_I=%d", hw_r_int, hw_i_int);
                    $finish;
                end

                // 累加浮點數 MSE
                err_r = hw_r_real - th_r_real;
                err_i = hw_i_real - th_i_real;
                sq_err_r = err_r * err_r;
                sq_err_i = err_i * err_i;
                // [新增] 累加這個 Key 的專屬 MSE
                key_mse_r = key_mse_r + sq_err_r;
                key_mse_i = key_mse_i + sq_err_i;
                total_mse_r = total_mse_r + sq_err_r;
                total_mse_i = total_mse_i + sq_err_i;

                if (i != 31) @(negedge clk);
                // $display("  %2d   | %5d | %10.4f | %8.4f || %5d | %10.4f | %8.4f", 
                //       i, hw_r_int, th_r_real, sq_err_r, hw_i_int, th_i_real, sq_err_i);
            end
            
            // [新增] 算完 32 點後，結算並印出這個 Key 的 MSE
            key_mse_r = key_mse_r / 32.0;
            key_mse_i = key_mse_i / 32.0;
            key_mse_total = key_mse_r + key_mse_i;
            
            // $display("Key = %4d | MSE_R: %10.4f | MSE_I: %10.4f | Total MSE: %10.4f", 
            //           k_int, key_mse_r, key_mse_i, key_mse_total);
        end

        // =====================================
        // 3. 結算最終全域 MSE 報告
        // =====================================
        // 總共 256 keys * 32 points = 8192 筆誤差
        total_mse_r = total_mse_r / 8192.0;
        total_mse_i = total_mse_i / 8192.0;

        $display("=======================================================================");
        $display(" 🎉 ALL 256 KEYS BIT-TRUE VERIFIED PERFECTLY! (0 Errors)");
        $display("=======================================================================");
        $display("               GLOBAL ERROR PERFORMANCE REPORT (8192 points)           ");
        $display("-----------------------------------------------------------------------");
        $display(" Global Real Channel MSE : %f", total_mse_r);
        $display(" Global Imag Channel MSE : %f", total_mse_i);
        $display(" Global Total MSE (R+I)  : %f", total_mse_r + total_mse_i);
        $display(" Total Exec cycle        : %3d", total_cycle);
        $display("=======================================================================\n");
        $finish;
    end
    
    initial begin
        $fsdbDumpfile("DFrFT_All_Keys.fsdb");
        $fsdbDumpvars(0, tb, "+mda");
    end

    // gate sim
    `ifdef SDF
        initial $sdf_annotate(`SDFFILE, u_chip);
    `endif

    // 全域掃描需要較長時間，放寬 Timeout 到 10ms
    initial begin
        #(`CYCLE * `MAX_CYCLE * 256)
        $display("Time out");
        $finish;
    end

endmodule