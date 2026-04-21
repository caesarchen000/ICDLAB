`timescale 1ns/1ps

module tb_FrFT_image_2d_dec;
    parameter CLK_PERIOD = 10;
    reg clk, rst_n, i_valid, o_ready, i_mode;
    reg [15:0] i_data;
    wire i_ready, o_valid;
    wire [7:0] o_data;

    integer fd_in, fd_out, scan_status;
    integer patch_idx, r, c, i;
    parameter TOTAL_PATCHES = 1200; 
    
    reg [32:0] transpose_ram [0:31][0:31]; 
    reg [7:0]  key_inv = -8'd50; // 🚨 解密金鑰：-50
    
    reg [31:0] flags_buf;
    reg [7:0]  payload_buf [0:127];
    reg [7:0]  b0, b1, b2, b3;

    FrFT dut (.clk(clk), .rst_n(rst_n), .i_valid(i_valid), .i_ready(i_ready), .o_ready(o_ready), .o_valid(o_valid), .i_mode(i_mode), .i_data(i_data), .o_data(o_data));
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        clk = 0; rst_n = 1; i_valid = 0; o_ready = 0; i_mode = 0; i_data = 0;
        fd_in  = $fopen("img_encoded_2d.txt", "r"); // 讀取 2D 密文
        fd_out = $fopen("img_decoded_2d.txt", "w");
        #(CLK_PERIOD*2) rst_n = 0; #(CLK_PERIOD*2) rst_n = 1; #(CLK_PERIOD*2);

        for (patch_idx = 0; patch_idx < TOTAL_PATCHES; patch_idx = patch_idx + 1) begin

            // [ STAGE 1: ROW PASS (從檔案讀取密文) ]
            for (r = 0; r < 32; r = r + 1) begin
                fork
                    begin // TX (Mode 1 讀取密文)
                        wait(i_ready == 1'b1); @(negedge clk);
                        i_mode = 1'b1; i_data = {8'b0, key_inv}; i_valid = 1'b1; @(posedge clk);
                        
                        // 讀取 Flag (4 Bytes) -> 先送高位，再送低位
                        scan_status=$fscanf(fd_in,"%x",b0); scan_status=$fscanf(fd_in,"%x",b1); scan_status=$fscanf(fd_in,"%x",b2); scan_status=$fscanf(fd_in,"%x",b3);
                        wait(i_ready == 1'b1); @(negedge clk); i_data = {b0, b1}; i_valid = 1'b1; @(posedge clk);
                        wait(i_ready == 1'b1); @(negedge clk); i_data = {b2, b3}; i_valid = 1'b1; @(posedge clk);
                        
                        // 讀取 Payload (128 Bytes) -> 先送高位，再送低位
                        for (c = 0; c < 32; c = c + 1) begin
                            scan_status=$fscanf(fd_in,"%x",b0); scan_status=$fscanf(fd_in,"%x",b1); scan_status=$fscanf(fd_in,"%x",b2); scan_status=$fscanf(fd_in,"%x",b3);
                            wait(i_ready == 1'b1); @(negedge clk); i_data = {b0, b1}; i_valid = 1'b1; @(posedge clk);
                            wait(i_ready == 1'b1); @(negedge clk); i_data = {b2, b3}; i_valid = 1'b1; @(posedge clk);
                        end
                        @(negedge clk); i_valid = 1'b0; @(posedge clk);
                    end
                    begin // RX (存入轉置 SRAM)
                        @(posedge clk); o_ready = 1'b1;
                        for (i = 0; i < 4; i = i + 1) begin wait(o_valid == 1'b1); @(posedge clk); flags_buf[(3-i)*8 +: 8] = o_data; end
                        for (i = 0; i < 128; i = i + 1) begin wait(o_valid == 1'b1); @(posedge clk); payload_buf[i] = o_data; end
                        @(negedge clk); o_ready = 1'b0;
                        for (c = 0; c < 32; c = c + 1) transpose_ram[r][c] = {flags_buf[c], payload_buf[c*4], payload_buf[c*4+1], payload_buf[c*4+2], payload_buf[c*4+3]};
                    end
                join
            end

            // [ STAGE 2: COLUMN PASS (從 SRAM 讀取) ]
            for (c = 0; c < 32; c = c + 1) begin
                fork
                    begin // TX
                        wait(i_ready == 1'b1); @(negedge clk);
                        i_mode = 1'b1; i_data = {8'b0, key_inv}; i_valid = 1'b1; @(posedge clk);
                        
                        flags_buf = 32'b0;
                        for (r = 0; r < 32; r = r + 1) flags_buf[r] = transpose_ram[r][c][32];
                        
                        wait(i_ready == 1'b1); @(negedge clk); i_data = flags_buf[31:16]; i_valid = 1'b1; @(posedge clk);
                        wait(i_ready == 1'b1); @(negedge clk); i_data = flags_buf[15:0];  i_valid = 1'b1; @(posedge clk);
                        
                        for (r = 0; r < 32; r = r + 1) begin
                            wait(i_ready == 1'b1); @(negedge clk); i_data = transpose_ram[r][c][31:16]; i_valid = 1'b1; @(posedge clk);
                            wait(i_ready == 1'b1); @(negedge clk); i_data = transpose_ram[r][c][15:0];  i_valid = 1'b1; @(posedge clk);
                        end
                        @(negedge clk); i_valid = 1'b0; @(posedge clk);
                    end
                    begin // RX (輸出最終明文)
                        @(posedge clk); o_ready = 1'b1;
                        for (i = 0; i < 132; i = i + 1) begin wait(o_valid == 1'b1); @(negedge clk); $fdisplay(fd_out, "%02x", o_data); @(posedge clk); end
                        @(negedge clk); o_ready = 1'b0;
                    end
                join
            end
            if ((patch_idx + 1) % 100 == 0) $display("Dec Progress: %0d / %0d", patch_idx + 1, TOTAL_PATCHES);
        end
        $display("DECRYPTION DONE!"); $fclose(fd_in); $fclose(fd_out); $finish;
    end
endmodule