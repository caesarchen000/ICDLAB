`timescale 1ns/1ps

module FrFT_tb;
    parameter CLK_PERIOD = 10;
    parameter N = 32;
    parameter NUM_PATTERNS = 256; // 定義連續測試 5 組
    parameter real MODEL_SCALE = 1.0;
    parameter real CMP_TOL = 1e-6;

    reg clk, rst_n;
    reg i_valid, o_ready;
    reg [15:0] i_data;
    wire i_ready, o_valid;
    wire [11:0] o_data;

    // 將記憶體深度擴大 5 倍
    reg [15:0] in_words [0:NUM_PATTERNS*N-1];
    reg [31:0] out_words [0:NUM_PATTERNS*N-1];
    reg [7:0]  key_mem [0:NUM_PATTERNS-1];
    real gt_real [0:NUM_PATTERNS*N-1];
    real gt_imag [0:NUM_PATTERNS*N-1];

    integer i, ret;
    integer total_err_cnt; // 統計 5 組的總錯誤
    integer log_fd, gt_fd;
    reg [11:0] dut_o_data_hist_real;

    FrFT_top #(
        .IOPORT_IN_W(16),
        .IOPORT_OUT_W(12)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .i_valid(i_valid), .i_ready(i_ready),
        .o_ready(o_ready), .o_valid(o_valid),
        .i_data(i_data),   .o_data(o_data)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // ==========================================================
    // Task: Input Driver
    // ==========================================================
    task send_payload_32;
        input [7:0] key;
        input integer pat_idx;
        integer k;
        reg signed [7:0] imag8, real8;
        begin
            wait(i_ready == 1'b1);
            // send key
            @(negedge clk);
            i_valid = 1'b1;
            i_data  = {8'h00, key};

            for (k = 0; k < N; k = k + 1) begin
                imag8 = $signed(in_words[pat_idx * N + k][15:8]);
                real8 = $signed(in_words[pat_idx * N + k][7:0]);
                @(negedge clk);
                i_valid = 1'b1;
                i_data  = {imag8, real8};
            end
            @(negedge clk);
            i_valid = 1'b0;
        end
    endtask

    // ==========================================================
    // Task: Output Monitor
    // ==========================================================
    task check_output_64;
        input [7:0] key;
        input integer pat_idx;
        integer cyc, idx, err_cnt;
        reg [11:0] got12;
        integer got_real_i, got_imag_i;
        real got_real_f, got_imag_f, exp_real_f, exp_imag_f, err_real_f, err_imag_f;
        real se_real_sum, se_imag_sum, mse_total;
        begin
            wait(o_valid == 1'b1);
            err_cnt = 0; se_real_sum = 0; se_imag_sum = 0;

            for (cyc = 0; cyc < 64; cyc = cyc + 1) begin
                idx = (pat_idx * N) + (cyc >> 1); // 加上 pattern offset
                @(negedge clk);
                got12 = o_data;

                if (cyc[0] == 1'b1) begin
                    got_real_i = s12_to_int(dut_o_data_hist_real);
                    got_imag_i = s12_to_int(got12);
                    got_real_f = got_real_i * MODEL_SCALE;
                    got_imag_f = got_imag_i * MODEL_SCALE;
                    exp_real_f = gt_real[idx];
                    exp_imag_f = gt_imag[idx];
                    err_real_f = got_real_f - exp_real_f;
                    err_imag_f = got_imag_f - exp_imag_f;
                    se_real_sum = se_real_sum + (err_real_f * err_real_f);
                    se_imag_sum = se_imag_sum + (err_imag_f * err_imag_f);

                    if ((abs_real(err_real_f) > CMP_TOL) || (abs_real(err_imag_f) > CMP_TOL))
                        err_cnt = err_cnt + 1;
                    
                    if (log_fd != 0)
                        $fdisplay(log_fd, "Pat%0d, idx%0d, %.6f, %.6f, err=%.6f", pat_idx, (cyc>>1), got_real_f, exp_real_f, err_real_f);
                end else begin
                    dut_o_data_hist_real = got12;
                end
            end
            
            total_err_cnt = total_err_cnt + err_cnt;
            mse_total = (se_real_sum + se_imag_sum) / 64.0;
            $display("Pattern %2d (key = %3d) - Err: %2d, MSE: %0f", pat_idx, key, err_cnt, mse_total);
        end
    endtask

    // Utility Functions
    function integer s12_to_int;
        input [11:0] v;
        begin
            s12_to_int = $signed(v);
        end
    endfunction

    function real abs_real;
        input real v;
        begin
            if (v < 0.0) abs_real = -v;
            else abs_real = v;
        end
    endfunction

    // ==========================================================
    // Main Initialization
    // ==========================================================
    initial begin
        $fsdbDumpfile("FrFT.fsdb");
        $fsdbDumpvars(0, FrFT_tb, "+mda");

        clk = 1'b0;
        rst_n = 1'b1;
        i_valid = 1'b0;
        o_ready = 1'b1; // 下游永遠 Ready，讓 Core 自由輸出
        i_data = 16'h0000;

        $readmemh("../00_TESTBED/pattern/gt_2path/input_words_32.hex", in_words);
        $readmemh("../00_TESTBED/pattern/gt_2path/output_words_32.hex", out_words);
        $readmemh("../00_TESTBED/pattern/gt_2path/key.hex", key_mem);
        gt_fd = $fopen("../00_TESTBED/pattern/gt_2path/output_float_32.txt", "r");
        for (i = 0; i < NUM_PATTERNS * N; i = i + 1) begin
            ret = $fscanf(gt_fd, "%f %f\n", gt_real[i], gt_imag[i]);
        end
        $fclose(gt_fd);

        // Reset
        repeat (2) @(negedge clk);
        rst_n = 1'b0;
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);
    end

    // ==========================================================
    // Parallel Block 1: Input Driver (不斷塞資料)
    // ==========================================================
    integer p;
    initial begin
        wait(rst_n == 1'b0);
        wait(rst_n == 1'b1);
        
        for (p = 0; p < NUM_PATTERNS; p = p + 1) begin
            send_payload_32(key_mem[p], p);
        end
    end

    // ==========================================================
    // Parallel Block 2: Output Monitor (不斷收資料並檢查)
    // ==========================================================
    integer q;
    initial begin
        wait(rst_n == 1'b0);
        wait(rst_n == 1'b1);
        total_err_cnt = 0;
        log_fd = $fopen("../00_TESTBED/pattern/gt_2path/error_log.txt", "w");

        for (q = 0; q < NUM_PATTERNS; q = q + 1) begin
            check_output_64(key_mem[q], q);
        end

        $fclose(log_fd);
        
        $display("\n----------------------------------------------------------");
        if (total_err_cnt == 0)
            $display("🚀 ALL %0d PATTERNS PASSED! Ping-Pong Overlapping Works!", NUM_PATTERNS);
        else
            $display("❌ TB FAIL: Total Errors = %0d", total_err_cnt);
        $display("----------------------------------------------------------\n");
        $finish;
    end

    // Timeout guard (擴大以容納 5 組測資)
    initial begin
        #(CLK_PERIOD * 500 * NUM_PATTERNS); 
        $display("TB TIMEOUT.");
        $finish;
    end

endmodule