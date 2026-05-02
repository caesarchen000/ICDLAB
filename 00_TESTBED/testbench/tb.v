`timescale 1ns/1ps

module FrFT_tb;
    parameter CLK_PERIOD = 10;
    parameter N = 32;
    parameter real MODEL_SCALE = 1.0;
    parameter real CMP_TOL = 1e-6;

    reg clk, rst_n;
    reg i_valid, o_ready;
    reg [15:0] i_data;
    wire i_ready, o_valid;
    wire [11:0] o_data; // expected by this TB requirement

    reg [15:0] in_words [0:N-1];
    reg [31:0] out_words [0:N-1];
    reg [7:0] key_mem [0:0];
    real gt_real [0:N-1];
    real gt_imag [0:N-1];

    integer i;
    integer err_cnt;
    reg [11:0] exp12;
    reg [11:0] got12;
    integer log_fd;
    integer gt_fd, ret;
    integer got_real_i, got_imag_i, exp_real_i, exp_imag_i;
    integer err_real_i, err_imag_i;
    real se_real_sum, se_imag_sum;
    real mse_real, mse_imag, mse_total;
    real got_real_f, got_imag_f, exp_real_f, exp_imag_f, err_real_f, err_imag_f;
    reg [11:0] dut_o_data_hist_real;

    // NOTE:
    // - Port names are kept same as FrFT_core.v.
    // - This TB assumes DUT output is 12-bit and streamed as:
    //   cycle0 real12, cycle1 imag12, repeat (64 cycles total).
    FrFT_top #(
        .IOPORT_IN_W(16),
        .IOPORT_OUT_W(12)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid(i_valid),
        .i_ready(i_ready),
        .o_ready(o_ready),
        .o_valid(o_valid),
        .i_data(i_data),
        .o_data(o_data)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    task send_key;
        input [7:0] key;
        begin
            // 1) o_ready=1, wait i_ready=1
            o_ready = 1'b1;
            wait(i_ready == 1'b1);

            // 2) i_valid 0->1 on negedge, output key in this cycle
            @(negedge clk);
            i_valid = 1'b1;
            i_data  = {8'h00, key};
            @(negedge clk);
            i_valid = 1'b0;
        end
    endtask

    task send_payload_32;
        integer k;
        reg signed [7:0] imag8, real8;
        begin
            // 3) wait 79 cycles with i_valid=0
            repeat (112) @(negedge clk);

            // 4) i_valid=1 for 32 cycles, output [image(8),real(8)]
            for (k = 0; k < N; k = k + 1) begin
                // in_words format: [15:8]=img, [7:0]=real
                imag8 = $signed(in_words[k][15:8]);
                real8 = $signed(in_words[k][7:0]);
                @(negedge clk);
                i_valid = 1'b1;
                i_data  = {imag8, real8}; // as requested: [image, real]
            end
            @(negedge clk);
            i_valid = 1'b0;
        end
    endtask

    task check_output_64;
        integer cyc;
        integer idx;
        begin
            // 5) wait o_valid=1
            wait(o_valid == 1'b1);

            // 6) next 64 cycles: real12 then imag12, evaluate and log
            err_cnt = 0;
            se_real_sum = 0;
            se_imag_sum = 0;
            log_fd = $fopen("../00_TESTBED/pattern/gt_2path/error_log.txt", "w");
            if (log_fd == 0) begin
                $display("ERROR: cannot open error_log.txt");
            end else begin
                $fdisplay(log_fd, "idx, got_real_f, exp_real_f, err_real_f, got_imag_f, exp_imag_f, err_imag_f");
            end

            for (cyc = 0; cyc < 64; cyc = cyc + 1) begin
                idx = cyc >> 1; // 0..31
                @(negedge clk);
                got12 = o_data;

                // Log one line per sample after imag cycle (odd cycle)
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
                        $fdisplay(log_fd, "%0d, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f",
                                  idx, got_real_f, exp_real_f, err_real_f, got_imag_f, exp_imag_f, err_imag_f);
                end else begin
                    dut_o_data_hist_real = got12;
                end
            end

            mse_real = se_real_sum / 32.0;
            mse_imag = se_imag_sum / 32.0;
            mse_total = (se_real_sum + se_imag_sum) / 64.0;
            if (log_fd != 0) begin
                $fdisplay(log_fd, "MSE_real=%0f", mse_real);
                $fdisplay(log_fd, "MSE_imag=%0f", mse_imag);
                $fdisplay(log_fd, "MSE_total=%0f", mse_total);
                $fclose(log_fd);
            end

            $display("----------------------------------------------------------\n");
            if (err_cnt == 0)
                $display("TB PASS: float-domain check matched GT (within tolerance).\n");
            else
                $display("TB FAIL: err_cnt=%0d (outside tolerance)\n", err_cnt);
            $display("MSE_real=%0f, MSE_imag=%0f, MSE_total=%0f\n", mse_real, mse_imag, mse_total);
            $display("----------------------------------------------------------\n");
        end
    endtask

    function integer s12_to_int;
        input [11:0] v;
        begin
            if (v[11] == 1'b1)
                s12_to_int = $signed(v);// - 12'h1000;
            else
                s12_to_int = v;
        end
    endfunction

    function [11:0] s16_to_s12;
        input [15:0] v16;
        integer s;
        begin
            s = (v16[15]) ? (v16 - 16'h10000) : v16;
            if (s > 2047)
                s16_to_s12 = 12'h7ff;
            else if (s < -2048)
                s16_to_s12 = 12'h800;
            else
                s16_to_s12 = s[11:0];
        end
    endfunction

    function real abs_real;
        input real v;
        begin
            if (v < 0.0) abs_real = -v;
            else abs_real = v;
        end
    endfunction

    initial begin
        $fsdbDumpfile("FrFT.fsdb");
        $fsdbDumpvars(0,FrFT_tb,"+mda");

        clk = 1'b0;
        rst_n = 1'b1;
        i_valid = 1'b0;
        o_ready = 1'b0;
        i_data = 16'h0000;

        $readmemh("../00_TESTBED/pattern/gt_2path/input_words_32.hex", in_words);
        $readmemh("../00_TESTBED/pattern/gt_2path/output_words_32.hex", out_words);
        $readmemh("../00_TESTBED/pattern/gt_2path/key.hex", key_mem);
        gt_fd = $fopen("../00_TESTBED/pattern/gt_2path/output_float_32.txt", "r");
        if (gt_fd == 0) begin
            $display("ERROR: cannot open output_float_32.txt");
            $finish;
        end
        for (i = 0; i < N; i = i + 1) begin
            ret = $fscanf(gt_fd, "%f %f\n", gt_real[i], gt_imag[i]);
            if (ret != 2) begin
                $display("ERROR: bad GT float format at line %0d", i);
                $finish;
            end
        end
        $fclose(gt_fd);

        // reset
        repeat (2) @(negedge clk);
        rst_n = 1'b0;
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        send_key(key_mem[0]);
        send_payload_32();
        check_output_64();

        $finish;
    end

    // timeout guard
    initial begin
        #(CLK_PERIOD * 800);
        $display("TB TIMEOUT.");
        $finish;
    end

endmodule
