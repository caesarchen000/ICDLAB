`timescale 1ns/1ps

module tb_FrFT_image;
    parameter CLK_PERIOD = 10;
    reg clk, rst_n, i_valid, o_ready, i_mode;
    reg [15:0] i_data;
    wire i_ready, o_valid;
    wire [7:0] o_data;

    integer fd_in, fd_out, scan_status;
    integer tx_block, tx_i;
    integer rx_block, rx_i;
    
    parameter TOTAL_BLOCKS = 38400; 
    
    reg [15:0] pixel_in;
    reg [7:0]  key_fwd = 8'd50; // 加密金鑰

    FrFT dut (
        .clk(clk), .rst_n(rst_n), .i_valid(i_valid), .i_ready(i_ready),
        .o_ready(o_ready), .o_valid(o_valid), .i_mode(i_mode), 
        .i_data(i_data), .o_data(o_data)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // --- 🚨 預防萬一的安全超時機制 ---
    initial begin
        #(CLK_PERIOD * TOTAL_BLOCKS * 500); 
        $display("ERROR: Simulation Timeout!");
        $finish;
    end

    initial begin
        clk = 0; rst_n = 1; i_valid = 0; o_ready = 0; i_mode = 0; i_data = 0;
        
        fd_in  = $fopen("../00_TESTBED/pattern/img_input.txt", "r");
        fd_out = $fopen("../00_TESTBED/pattern/img_encoded.txt", "w");
        
        if (fd_in == 0) begin
            $display("ERROR: Cannot open img_input.txt!");
            $finish;
        end

        #(CLK_PERIOD*2) rst_n = 0; #(CLK_PERIOD*2) rst_n = 1; #(CLK_PERIOD*2);

        $display("========================================");
        $display("   TAPE-OUT: 2D IMAGE ENCRYPTION START  ");
        $display("   Total Blocks to process: %0d", TOTAL_BLOCKS);
        $display("========================================");

        fork
            // --- Process 1: 資料傳送端 (TX) ---
            begin
                for (tx_block = 0; tx_block < TOTAL_BLOCKS; tx_block = tx_block + 1) begin
                    wait(i_ready == 1'b1); @(negedge clk);
                    i_mode = 1'b0; i_data = {8'b0, key_fwd}; i_valid = 1'b1; @(posedge clk);
                    
                    wait(i_ready == 1'b1); @(negedge clk); i_data = 16'd0; @(posedge clk);
                    wait(i_ready == 1'b1); @(negedge clk); i_data = 16'd0; @(posedge clk);
                    
                    for (tx_i = 0; tx_i < 32; tx_i = tx_i + 1) begin
                        scan_status = $fscanf(fd_in, "%h", pixel_in);
                        // 防呆：若檔案提早結束，補 0 防止變數殘留
                        if (scan_status != 1) pixel_in = 16'd0; 
                        
                        wait(i_ready == 1'b1); @(negedge clk); 
                        i_data = pixel_in; i_valid = 1'b1; @(posedge clk);
                    end
                    @(negedge clk); i_valid = 1'b0; @(posedge clk);
                    
                    // if ((tx_block + 1) % 1000 == 0 || (tx_block + 1) == TOTAL_BLOCKS)
                    //     $display("TX Progress: %0d / %0d Blocks", tx_block + 1, TOTAL_BLOCKS);
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
                        $display("RX Progress: %0d / %0d Blocks", rx_block + 1, TOTAL_BLOCKS);

                    // 🚨 終極強制結束機制：只要 RX 收到全部資料，立刻關檔並結束！
                    if ((rx_block + 1) == TOTAL_BLOCKS) begin
                        $display("========================================");
                        $display("   IMAGE ENCRYPTION COMPLETED!");
                        $display("   File Successfully Flushed to Disk.   ");
                        $display("========================================");
                        $fclose(fd_in);
                        $fclose(fd_out);
                        $finish; // 直接強制結束模擬，破除所有死結！
                    end
                end
            end
        join
    end
endmodule