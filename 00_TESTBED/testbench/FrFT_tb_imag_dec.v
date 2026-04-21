`timescale 1ns/1ps

module tb_FrFT_image_dec;
    parameter CLK_PERIOD = 10;
    reg clk, rst_n, i_valid, o_ready, i_mode;
    reg [15:0] i_data;
    wire i_ready, o_valid;
    wire [7:0] o_data;

    integer fd_in, fd_out, scan_status;
    integer tx_block, tx_i;
    integer rx_block, rx_i;
    
    parameter TOTAL_BLOCKS = 38400; 
    
    reg [7:0] b0, b1, b2, b3;
    reg [7:0] key_inv = -8'd50; // 🚀 解密金鑰：-50 (自動轉為 8-bit 的 206)

    FrFT dut (
        .clk(clk), .rst_n(rst_n), .i_valid(i_valid), .i_ready(i_ready),
        .o_ready(o_ready), .o_valid(o_valid), .i_mode(i_mode), 
        .i_data(i_data), .o_data(o_data)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // 預防超時死結
    initial begin
        #(CLK_PERIOD * TOTAL_BLOCKS * 500); 
        $display("ERROR: Simulation Timeout!");
        $finish;
    end

    initial begin
        clk = 0; rst_n = 1; i_valid = 0; o_ready = 0; i_mode = 0; i_data = 0;
        
        fd_in  = $fopen("../00_TESTBED/pattern/img_encoded.txt", "r"); // 讀取密文
        fd_out = $fopen("../00_TESTBED/pattern/img_decoded.txt", "w"); // 輸出解密後的明文
        
        if (fd_in == 0) begin
            $display("ERROR: Cannot open img_encoded.txt!");
            $finish;
        end

        #(CLK_PERIOD*2) rst_n = 0; #(CLK_PERIOD*2) rst_n = 1; #(CLK_PERIOD*2);

        $display("========================================");
        $display("   TAPE-OUT: 2D IMAGE DECRYPTION START  ");
        $display("   Total Blocks to process: %0d", TOTAL_BLOCKS);
        $display("========================================");

        fork
            // --- Process 1: 資料傳送端 (TX) - Mode 1 模式 ---
            begin
                for (tx_block = 0; tx_block < TOTAL_BLOCKS; tx_block = tx_block + 1) begin
                    // 1. 傳送 Key
                    wait(i_ready == 1'b1); @(negedge clk);
                    i_mode = 1'b1; i_data = {8'b0, key_inv}; i_valid = 1'b1; @(posedge clk);
                    
                    // 2. 讀取並傳送 4 Bytes 的 Flags (拼成 2 個 16-bit)
                    scan_status = $fscanf(fd_in, "%x", b0); scan_status = $fscanf(fd_in, "%x", b1);
                    scan_status = $fscanf(fd_in, "%x", b2); scan_status = $fscanf(fd_in, "%x", b3);
                    wait(i_ready == 1'b1); @(negedge clk); i_data = {b0, b1}; i_valid = 1'b1; @(posedge clk);
                    wait(i_ready == 1'b1); @(negedge clk); i_data = {b2, b3}; i_valid = 1'b1; @(posedge clk);
                    
                    // 3. 讀取並傳送 128 Bytes 的 Payload (32 個 Words)
                    for (tx_i = 0; tx_i < 32; tx_i = tx_i + 1) begin
                        scan_status = $fscanf(fd_in, "%x", b0); scan_status = $fscanf(fd_in, "%x", b1);
                        scan_status = $fscanf(fd_in, "%x", b2); scan_status = $fscanf(fd_in, "%x", b3);
                        wait(i_ready == 1'b1); @(negedge clk); i_data = {b0, b1}; i_valid = 1'b1; @(posedge clk);
                        wait(i_ready == 1'b1); @(negedge clk); i_data = {b2, b3}; i_valid = 1'b1; @(posedge clk);
                    end
                    @(negedge clk); i_valid = 1'b0; @(posedge clk);
                    
                    if ((tx_block + 1) % 1000 == 0 || (tx_block + 1) == TOTAL_BLOCKS)
                        $display("TX (Dec) Progress: %0d / %0d Blocks", tx_block + 1, TOTAL_BLOCKS);
                end
            end
            
            // --- Process 2: 資料接收端 (RX) ---
            begin
                @(posedge clk); o_ready = 1'b1;
                
                for (rx_block = 0; rx_block < TOTAL_BLOCKS; rx_block = rx_block + 1) begin
                    for (rx_i = 0; rx_i < 132; rx_i = rx_i + 1) begin
                        wait(o_valid == 1'b1); 
                        @(negedge clk);
                        $fdisplay(fd_out, "%02x", o_data);
                        @(posedge clk);
                    end
                    
                    if ((rx_block + 1) % 1000 == 0 || (rx_block + 1) == TOTAL_BLOCKS)
                        $display("RX (Dec) Progress: %0d / %0d Blocks", rx_block + 1, TOTAL_BLOCKS);

                    // 安全強制結束
                    if ((rx_block + 1) == TOTAL_BLOCKS) begin
                        $display("========================================");
                        $display("   IMAGE DECRYPTION COMPLETED!          ");
                        $display("========================================");
                        $fclose(fd_in);
                        $fclose(fd_out);
                        $finish;
                    end
                end
            end
        join
    end
endmodule