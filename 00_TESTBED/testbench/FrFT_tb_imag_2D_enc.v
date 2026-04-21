`timescale 1ns/1ps

module tb_FrFT_image_2d;
    parameter CLK_PERIOD = 10;
    reg clk, rst_n, i_valid, o_ready, i_mode;
    reg [15:0] i_data;
    wire i_ready, o_valid;
    wire [7:0] o_data;

    integer fd_in, fd_out, scan_status;
    integer patch_idx, r, c, i;
    parameter TOTAL_PATCHES = 1200; 
    
    reg [15:0] patch_in      [0:31][0:31]; 
    reg [32:0] transpose_ram [0:31][0:31]; 
    reg [7:0]  key_fwd = 8'd50;
    
    reg [31:0] flags_buf;
    reg [7:0]  payload_buf [0:127];

    FrFT dut (.clk(clk), .rst_n(rst_n), .i_valid(i_valid), .i_ready(i_ready), .o_ready(o_ready), .o_valid(o_valid), .i_mode(i_mode), .i_data(i_data), .o_data(o_data));
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        clk = 0; rst_n = 1; i_valid = 0; o_ready = 0; i_mode = 0; i_data = 0;
        fd_in  = $fopen("img_input.txt", "r");
        fd_out = $fopen("img_encoded_2d.txt", "w");
        #(CLK_PERIOD*2) rst_n = 0; #(CLK_PERIOD*2) rst_n = 1; #(CLK_PERIOD*2);

        for (patch_idx = 0; patch_idx < TOTAL_PATCHES; patch_idx = patch_idx + 1) begin
            for (r = 0; r < 32; r = r + 1) begin
                for (c = 0; c < 32; c = c + 1) begin
                    scan_status = $fscanf(fd_in, "%h", patch_in[r][c]);
                    if (scan_status != 1) patch_in[r][c] = 16'd0;
                end
            end

            // [ STAGE 1: ROW PASS ]
            for (r = 0; r < 32; r = r + 1) begin
                fork
                    begin // TX
                        wait(i_ready == 1'b1); @(negedge clk);
                        i_mode = 1'b0; i_data = {8'b0, key_fwd}; i_valid = 1'b1; @(posedge clk);
                        wait(i_ready == 1'b1); @(negedge clk); i_data = 16'd0; @(posedge clk);
                        wait(i_ready == 1'b1); @(negedge clk); i_data = 16'd0; @(posedge clk);
                        for (c = 0; c < 32; c = c + 1) begin
                            wait(i_ready == 1'b1); @(negedge clk); i_data = patch_in[r][c]; i_valid = 1'b1; @(posedge clk);
                        end
                        @(negedge clk); i_valid = 1'b0; @(posedge clk);
                    end
                    begin // RX
                        @(posedge clk); o_ready = 1'b1;
                        for (i = 0; i < 4; i = i + 1) begin wait(o_valid == 1'b1); @(posedge clk); flags_buf[(3-i)*8 +: 8] = o_data; end
                        for (i = 0; i < 128; i = i + 1) begin wait(o_valid == 1'b1); @(posedge clk); payload_buf[i] = o_data; end
                        @(negedge clk); o_ready = 1'b0;
                        for (c = 0; c < 32; c = c + 1) transpose_ram[r][c] = {flags_buf[c], payload_buf[c*4], payload_buf[c*4+1], payload_buf[c*4+2], payload_buf[c*4+3]};
                    end
                join
            end

            // [ STAGE 2: COLUMN PASS ]
            for (c = 0; c < 32; c = c + 1) begin
                fork
                    begin // TX
                        wait(i_ready == 1'b1); @(negedge clk);
                        i_mode = 1'b1; i_data = {8'b0, key_fwd}; i_valid = 1'b1; @(posedge clk);
                        
                        flags_buf = 32'b0;
                        for (r = 0; r < 32; r = r + 1) flags_buf[r] = transpose_ram[r][c][32];
                        
                        // 🚨 修正：先送高位 [31:16] 再送低位 [15:0] 完美對齊硬體！
                        wait(i_ready == 1'b1); @(negedge clk); i_data = flags_buf[31:16]; i_valid = 1'b1; @(posedge clk);
                        wait(i_ready == 1'b1); @(negedge clk); i_data = flags_buf[15:0];  i_valid = 1'b1; @(posedge clk);
                        
                        for (r = 0; r < 32; r = r + 1) begin
                            // 🚨 修正：先送高位 [31:16] 再送低位 [15:0] 完美對齊硬體！
                            wait(i_ready == 1'b1); @(negedge clk); i_data = transpose_ram[r][c][31:16]; i_valid = 1'b1; @(posedge clk);
                            wait(i_ready == 1'b1); @(negedge clk); i_data = transpose_ram[r][c][15:0];  i_valid = 1'b1; @(posedge clk);
                        end
                        @(negedge clk); i_valid = 1'b0; @(posedge clk);
                    end
                    begin // RX
                        @(posedge clk); o_ready = 1'b1;
                        for (i = 0; i < 132; i = i + 1) begin wait(o_valid == 1'b1); @(negedge clk); $fdisplay(fd_out, "%02x", o_data); @(posedge clk); end
                        @(negedge clk); o_ready = 1'b0;
                    end
                join
            end
            if ((patch_idx + 1) % 100 == 0) $display("Enc Progress: %0d / %0d", patch_idx + 1, TOTAL_PATCHES);
        end
        $display("ENCRYPTION DONE!"); $fclose(fd_in); $fclose(fd_out); $finish;
    end
endmodule