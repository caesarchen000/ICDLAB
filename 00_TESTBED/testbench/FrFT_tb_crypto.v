`timescale 1ns/1ps

module tb_FrFT_crypto;
    parameter CLK_PERIOD = 10;
    reg clk, rst_n, i_valid, o_ready, i_mode;
    reg [15:0] i_data;
    wire i_ready, o_valid;
    wire [7:0] o_data;

    integer fd_in, scan_status;
    integer test_idx, i, j, pass_count, fail_count, frame_err;
    
    reg [7:0] key_fwd, key_inv;
    reg [32:0] orig_words [0:31];
    reg [32:0] enc_words  [0:31];
    reg [32:0] dec_words  [0:31];
    
    reg [31:0] flags_buffer;
    reg [31:0] payload_buffer;

    FrFT dut (
        .clk(clk), .rst_n(rst_n), .i_valid(i_valid), .i_ready(i_ready),
        .o_ready(o_ready), .o_valid(o_valid), .i_mode(i_mode), 
        .i_data(i_data), .o_data(o_data)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        clk = 0; rst_n = 1; i_valid = 0; o_ready = 0; i_mode = 0; i_data = 0;
        pass_count = 0; fail_count = 0;
        fd_in = $fopen("../00_TESTBED/pattern/stimulus_crypto.txt", "r");
        #(CLK_PERIOD*2) rst_n = 0; #(CLK_PERIOD*2) rst_n = 1; #(CLK_PERIOD*2);

        $display("========================================");
        $display("   TAPE-OUT CRYPTO LOSSLESS VERIFICATION");
        $display("========================================");

        for (test_idx = 0; test_idx < 50; test_idx = test_idx + 1) begin
            frame_err = 0;
            // 讀取 Key 與 32 筆原始資料
            scan_status = $fscanf(fd_in, "%h", key_fwd);
            if (scan_status != 1) $finish; 
            for (i=0; i<32; i=i+1) scan_status = $fscanf(fd_in, "%h", orig_words[i]);

            // ==========================================
            // [ PASS 1 : ENCRYPTION (Sender) ]
            // ==========================================
            wait(i_ready == 1'b1); @(negedge clk);
            i_mode = 1'b1; i_data = {8'b0, key_fwd}; i_valid = 1'b1; @(posedge clk); #1;
            
            flags_buffer = 0;
            for (i=0; i<32; i=i+1) if (orig_words[i][32]) flags_buffer[i] = 1'b1;
            
            wait(i_ready == 1'b1); @(negedge clk); i_data = flags_buffer[31:16]; @(posedge clk); #1;
            wait(i_ready == 1'b1); @(negedge clk); i_data = flags_buffer[15:0];  @(posedge clk); #1;
            
            for (i=0; i<32; i=i+1) begin
                wait(i_ready == 1'b1); @(negedge clk); i_data = orig_words[i][31:16]; @(posedge clk); #1;
                wait(i_ready == 1'b1); @(negedge clk); i_data = orig_words[i][15:0];  @(posedge clk); #1;
            end
            @(negedge clk); i_valid = 1'b0; @(posedge clk);

            o_ready = 1'b1;
            for (i=0; i<4; i=i+1) begin wait(o_valid == 1'b1); @(posedge clk); flags_buffer[(3-i)*8 +: 8] = o_data; end
            for (i=0; i<32; i=i+1) begin
                for (j=0; j<4; j=j+1) begin wait(o_valid == 1'b1); @(posedge clk); payload_buffer[(3-j)*8 +: 8] = o_data; end
                enc_words[i] = {flags_buffer[31-i], payload_buffer}; 
            end
            o_ready = 1'b0;

            // ==========================================
            // [ PASS 2 : DECRYPTION (Receiver) ]
            // ==========================================
            key_inv = -key_fwd; // 二補數負值，喚醒 ROM 裡的模反元素！
            
            wait(i_ready == 1'b1); @(negedge clk);
            i_mode = 1'b1; i_data = {8'b0, key_inv}; i_valid = 1'b1; @(posedge clk); #1;
            
            flags_buffer = 0;
            for (i=0; i<32; i=i+1) if (enc_words[i][32]) flags_buffer[i] = 1'b1;
            
            wait(i_ready == 1'b1); @(negedge clk); i_data = flags_buffer[31:16]; @(posedge clk); #1;
            wait(i_ready == 1'b1); @(negedge clk); i_data = flags_buffer[15:0];  @(posedge clk); #1;
            
            for (i=0; i<32; i=i+1) begin
                wait(i_ready == 1'b1); @(negedge clk); i_data = enc_words[i][31:16]; @(posedge clk); #1;
                wait(i_ready == 1'b1); @(negedge clk); i_data = enc_words[i][15:0];  @(posedge clk); #1;
            end
            @(negedge clk); i_valid = 1'b0; @(posedge clk);

            o_ready = 1'b1;
            for (i=0; i<4; i=i+1) begin wait(o_valid == 1'b1); @(posedge clk); flags_buffer[(3-i)*8 +: 8] = o_data; end
            for (i=0; i<32; i=i+1) begin
                for (j=0; j<4; j=j+1) begin wait(o_valid == 1'b1); @(posedge clk); payload_buffer[(3-j)*8 +: 8] = o_data; end
                dec_words[i] = {flags_buffer[31-i], payload_buffer}; 
                
                // 🚀 最終無損核對！
                if (dec_words[i] !== orig_words[i]) begin
                    $display("  [Test %0d] RECONSTRUCTION ERROR at %0d: Expected %09x, Got %09x", test_idx, i, orig_words[i], dec_words[i]);
                    frame_err = frame_err + 1;
                end
            end
            o_ready = 1'b0;

            if (frame_err == 0) begin
                pass_count = pass_count + 1;
                $display("[Test %0d] PERFECT RECONSTRUCTION (Key %0d -> %0d)", test_idx, key_fwd, key_inv);
            end else fail_count = fail_count + 1;
        end
        $display(" TOTAL TESTS : %0d, PASSED: %0d, FAILED: %0d", pass_count + fail_count, pass_count, fail_count);
        $finish;
    end
endmodule