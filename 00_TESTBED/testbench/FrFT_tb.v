`timescale 1ns/1ps

module FrFT_tb;
    parameter CLK_PERIOD = 10;
    
    reg clk, rst_n, i_valid, o_ready, i_mode;
    reg [15:0] i_data;
    
    wire i_ready, o_valid;
    wire [7:0] o_data;

    integer fd_in, fd_gold, scan_status, fd_hw_out;
    integer test_idx, i, j, pass_count, fail_count, frame_err;
    
    reg [15:0] read_mode, read_key;
    reg [32:0] gold_val, hw_word;
    reg [15:0] data_in_16;
    
    reg [31:0] hw_flags;
    reg [31:0] hw_payload;

    FrFT dut (
        .clk(clk), .rst_n(rst_n), .i_valid(i_valid), .i_ready(i_ready),
        .o_ready(o_ready), .o_valid(o_valid), .i_mode(i_mode), 
        .i_data(i_data), .o_data(o_data)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        $fsdbDumpfile("FrFT.fsdb");
        $fsdbDumpvars(0,FrFT_tb,"+all");

        clk = 0; rst_n = 1; i_valid = 0; o_ready = 0; i_mode = 0; i_data = 0;
        pass_count = 0; fail_count = 0;

        fd_in   = $fopen("../00_TESTBED/pattern/stimulus.txt", "r");
        fd_gold = $fopen("../00_TESTBED/pattern/golden.txt", "r");
        fd_hw_out = $fopen("../00_TESTBED/pattern/hw_output.txt", "w");

        #(CLK_PERIOD*2) rst_n = 0; #(CLK_PERIOD*2) rst_n = 1; #(CLK_PERIOD*2);

        $display("========================================");
        $display("   TAPE-OUT 33-bit WORD VERIFICATION    ");
        $display("========================================");

        for (test_idx = 0; test_idx < 50; test_idx = test_idx + 1) begin
            frame_err = 0;
            scan_status = $fscanf(fd_in, "%h %h", read_mode, read_key);
            if (scan_status != 2) $finish; 

            // 1. Send Control Word
            wait(i_ready == 1'b1); @(negedge clk);
            i_mode = read_mode[0]; i_data = read_key; i_valid = 1'b1;
            @(posedge clk); #1;

            // 2. Send Flags Preamble
            scan_status = $fscanf(fd_in, "%h", data_in_16);
            wait(i_ready == 1'b1); @(negedge clk); i_data = data_in_16; @(posedge clk); #1;
            scan_status = $fscanf(fd_in, "%h", data_in_16);
            wait(i_ready == 1'b1); @(negedge clk); i_data = data_in_16; @(posedge clk); #1;

            // 3. Send Data Payload
            if (read_mode == 0) begin
                for (i = 0; i < 32; i = i + 1) begin
                    scan_status = $fscanf(fd_in, "%h", data_in_16);
                    wait(i_ready == 1'b1); @(negedge clk); i_data = data_in_16; @(posedge clk); #1;
                end
            end else begin
                for (i = 0; i < 64; i = i + 1) begin
                    scan_status = $fscanf(fd_in, "%h", data_in_16);
                    wait(i_ready == 1'b1); @(negedge clk); i_data = data_in_16; @(posedge clk); #1;
                end
            end
            @(negedge clk); i_valid = 1'b0; @(posedge clk);

            // 4. Verify Output Words
            o_ready = 1'b1;
            
            // 4-A. Read 4 Bytes of Flag
            for (i = 0; i < 4; i = i + 1) begin
                wait(o_valid == 1'b1); @(posedge clk);
                if (i == 0) hw_flags[7:0]   = o_data;
                if (i == 1) hw_flags[15:8]  = o_data;
                if (i == 2) hw_flags[23:16] = o_data;
                if (i == 3) hw_flags[31:24] = o_data;
            end

            // 4-B. Read 32 Words (each 4 Bytes)
            for (i = 0; i < 32; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin
                    wait(o_valid == 1'b1); @(posedge clk);
                    if (j == 0) hw_payload[31:24] = o_data;
                    if (j == 1) hw_payload[23:16] = o_data;
                    if (j == 2) hw_payload[15:8]  = o_data;
                    if (j == 3) hw_payload[7:0]   = o_data;
                end
                
                hw_word = {hw_flags[i], hw_payload}; // 拼裝 33-bit
                
                $fdisplay(fd_hw_out, "%09x", hw_word);
                scan_status = $fscanf(fd_gold, "%h", gold_val);
                if (hw_word !== gold_val) begin
                    $display("  [Test %0d] ERROR at word %0d: Expected %09x, Got %09x", test_idx, i, gold_val, hw_word);
                    frame_err = frame_err + 1;
                end
            end
            o_ready = 1'b0;

            if (frame_err == 0) begin
                pass_count = pass_count + 1;
                $display("[Test %0d] PASS", test_idx);
            end else fail_count = fail_count + 1;
        end
        
        $display(" TOTAL TESTS : %0d, PASSED: %0d, FAILED: %0d", pass_count + fail_count, pass_count, fail_count);
        if (fail_count == 0) $display("\n >>> PERFECT SCORE! READY FOR TAPE-OUT! <<< \n");
        $finish;
    end
endmodule