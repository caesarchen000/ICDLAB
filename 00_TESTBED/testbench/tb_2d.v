`timescale 1ns/10ps
`define CYCLE      20.0
`define MAX_CYCLE  50000000 
`define SDFFILE    "../02_SYN/Netlist/CHIP_syn.sdf"

module tb;
    reg clk, rst_n;
    reg         i_valid;
    wire        i_ready;
    reg  [15:0] i_data;
    reg         o_ready;
    wire        o_valid;
    wire [10:0] o_data;
    
    CHIP u_chip (
        .clk(clk), .rst_n(rst_n),
        .i_valid(i_valid), .i_ready(i_ready),
        .o_ready(o_ready), .o_valid(o_valid),
        .i_data(i_data), .o_data(o_data)
    );

    // 擴大記憶體以容納真實圖片 (最大支援 256x256 像素 = 65536)
    reg [15:0] mem_a [0:65535]; 
    reg [15:0] mem_b [0:65535]; 

    integer i, r, c, fd_in, fd_enc, fd_dec, code;
    integer hw_r_int, hw_i_int;
    integer i_val, r_val;
    integer total_pixels, num_blocks, blk, b_offset;

    // Match Python rtl_img_tb.py / hw_sim_2d (fixed key, decrypt col then row)
    localparam [7:0] KEY_ENC = 8'd40;
    localparam signed [7:0] KEY_DEC = -8'sd40;

    always #(`CYCLE/2) clk = ~clk;

    // ==============================================================
    // [核心靈魂] 動態範圍縮放與四捨五入 (Round-to-nearest)
    // ==============================================================
    function [7:0] clip_to_8(input signed [10:0] val);
        reg signed [11:0] rounded; // 多給 1 bit 避免加法溢位
        begin
            // [修復核心] 加上 4 再平移，達成完美的四捨五入，消除量化漂移
            rounded = (val + 12'sd4) >>> 3; 
            
            if (rounded > 12'sd127) clip_to_8 = 8'sd127;
            else if (rounded < -12'sd128) clip_to_8 = -8'sd128;
            else clip_to_8 = rounded[7:0];
        end
    endfunction

    task process_1d_burst;
        input [7:0] t_key;
        input integer dir; 
        input integer stride_in, offset_in;
        input integer stride_out, offset_out;
        integer k;
        begin
            wait(i_ready == 1'b1);
            @(negedge clk);
            i_valid = 1; i_data = {8'd0, t_key}; 
            @(negedge clk);
            
            for (k = 0; k < 32; k = k + 1) begin
                i_valid = 1;
                i_data = (dir == 0) ? mem_a[offset_in + k*stride_in] : mem_b[offset_in + k*stride_in];
                @(negedge clk);
            end
            i_valid = 0;

            o_ready = 1;
            wait(o_valid == 1'b1);
            @(negedge clk);
            for (k = 0; k < 32; k = k + 1) begin
                hw_r_int = $signed(o_data);
                @(negedge clk);
                hw_i_int = $signed(o_data);
                
                if (dir == 0) mem_b[offset_out + k*stride_out] = {clip_to_8(hw_i_int), clip_to_8(hw_r_int)};
                else          mem_a[offset_out + k*stride_out] = {clip_to_8(hw_i_int), clip_to_8(hw_r_int)};
                
                if (k != 31) @(negedge clk);
            end
            o_ready = 0;
        end
    endtask

    initial begin
        fd_in = $fopen("../00_TESTBED/pattern/img_in.txt", "r");
        total_pixels = 0;
        while (!$feof(fd_in)) begin
            code = $fscanf(fd_in, "%h %h\n", i_val, r_val);
            if (code == 2) begin
                mem_a[total_pixels] = {i_val[15:0], r_val[15:0]};
                total_pixels = total_pixels + 1;
            end
        end
        $fclose(fd_in);

        num_blocks = total_pixels / 1024;
        $display("✅ 成功載入 %d 個像素，共 %d 個 32x32 Blocks", total_pixels, num_blocks);

        clk = 0; rst_n = 1; i_valid = 0; i_data = 0; o_ready = 0;
        #15 rst_n = 0; #20 rst_n = 1; #10;

        $display("==================================================");
        $display("   [1/2] 2D encrypt (rows then cols, key=%0d)", KEY_ENC);
        $display("==================================================");
        for (blk = 0; blk < num_blocks; blk = blk + 1) begin
            b_offset = blk * 1024;
            for (r = 0; r < 32; r = r + 1) process_1d_burst(KEY_ENC, 0, 1, b_offset + r*32, 1, b_offset + r*32);
            for (c = 0; c < 32; c = c + 1) process_1d_burst(KEY_ENC, 1, 32, b_offset + c, 32, b_offset + c);
        end

        fd_enc = $fopen("../00_TESTBED/pattern/img_enc.txt", "w");
        for (i = 0; i < total_pixels; i = i + 1) $fwrite(fd_enc, "%02X %02X\n", mem_a[i][15:8], mem_a[i][7:0]);
        $fclose(fd_enc);

        $display("==================================================");
        $display("   [2/2] 2D decrypt (cols then rows, key=%0d)", KEY_DEC);
        $display("==================================================");
        for (blk = 0; blk < num_blocks; blk = blk + 1) begin
            b_offset = blk * 1024;
            for (c = 0; c < 32; c = c + 1) process_1d_burst(KEY_DEC, 0, 32, b_offset + c, 32, b_offset + c);
            for (r = 0; r < 32; r = r + 1) process_1d_burst(KEY_DEC, 1, 1, b_offset + r*32, 1, b_offset + r*32);
        end

        fd_dec = $fopen("../00_TESTBED/pattern/img_dec.txt", "w");
        for (i = 0; i < total_pixels; i = i + 1) $fwrite(fd_dec, "%02X %02X\n", mem_a[i][15:8], mem_a[i][7:0]);
        $fclose(fd_dec);

        $display("\n🎉 2D IMAGE PROCESSING COMPLETE! 輸出檔案完成！");
        $finish;
    end
    
    initial begin
        #(`CYCLE * `MAX_CYCLE) $display("Time out"); $finish;
    end
endmodule