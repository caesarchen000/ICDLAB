`timescale 1ns/10ps
`define CYCLE      20.0
`define MAX_CYCLE  50000000

// One channel per compile: +define+CH_R | +define+CH_G | +define+CH_B (default CH_R)
`ifndef CH_R
`ifndef CH_G
`ifndef CH_B
`define CH_R
`endif
`endif
`endif

`ifdef CH_R
  `define FIMG_IN  "../00_TESTBED/pattern/img_r.txt"
  `define FENC1D   "../00_TESTBED/pattern/r_enc1d.txt"
  `define FENC2D   "../00_TESTBED/pattern/r_enc2d.txt"
  `define FDEC1D   "../00_TESTBED/pattern/r_dec1d.txt"
  `define FDEC2D   "../00_TESTBED/pattern/r_dec2d.txt"
`elsif CH_G
  `define FIMG_IN  "../00_TESTBED/pattern/img_g.txt"
  `define FENC1D   "../00_TESTBED/pattern/g_enc1d.txt"
  `define FENC2D   "../00_TESTBED/pattern/g_enc2d.txt"
  `define FDEC1D   "../00_TESTBED/pattern/g_dec1d.txt"
  `define FDEC2D   "../00_TESTBED/pattern/g_dec2d.txt"
`else
  `define FIMG_IN  "../00_TESTBED/pattern/img_b.txt"
  `define FENC1D   "../00_TESTBED/pattern/b_enc1d.txt"
  `define FENC2D   "../00_TESTBED/pattern/b_enc2d.txt"
  `define FDEC1D   "../00_TESTBED/pattern/b_dec1d.txt"
  `define FDEC2D   "../00_TESTBED/pattern/b_dec2d.txt"
`endif

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

    // up to 320x256 canvas (~80k pixels)
    reg [15:0] mem_a [0:131071];
    reg [15:0] mem_b [0:131071];

    integer i, r, c, fd_in, fd_out, code;
    integer hw_r_int, hw_i_int;
    integer pixel_u8, real_s8;
    integer total_pixels, num_blocks, blk, b_offset;

    localparam [7:0] KEY_ENC = 8'd40;
    localparam signed [7:0] KEY_DEC = -8'sd40;

    always #(`CYCLE/2) clk = ~clk;

    function [7:0] saturate_8;
        input signed [10:0] val;
        begin
            if (val > 11'sd127)
                saturate_8 = 8'sd127;
            else if (val < -11'sd128)
                saturate_8 = -8'sd128;
            else
                saturate_8 = val[7:0];
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
            i_valid = 1;
            i_data = {8'd0, t_key};
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

                if (dir == 0)
                    mem_b[offset_out + k*stride_out] = {saturate_8(hw_i_int), saturate_8(hw_r_int)};
                else
                    mem_a[offset_out + k*stride_out] = {saturate_8(hw_i_int), saturate_8(hw_r_int)};

                if (k != 31) @(negedge clk);
            end
            o_ready = 0;
        end
    endtask

    initial begin
        fd_in = $fopen(`FIMG_IN, "r");
        if (fd_in == 0) begin
            $display("ERROR: cannot open channel input file");
            $finish;
        end

        total_pixels = 0;
        while (!$feof(fd_in)) begin
            code = $fscanf(fd_in, "%d", pixel_u8);
            if (code == 1) begin
                real_s8 = pixel_u8 - 128;
                mem_a[total_pixels] = {8'd0, real_s8[7:0]};
                total_pixels = total_pixels + 1;
            end
        end
        $fclose(fd_in);

        num_blocks = total_pixels / 1024;
        $display("pixels=%0d blocks=%0d", total_pixels, num_blocks);

        clk = 0;
        rst_n = 1;
        i_valid = 0;
        i_data = 0;
        o_ready = 0;
        #15 rst_n = 0;
        #20 rst_n = 1;
        #10;

        $display("encrypt rows (1D)");
        for (blk = 0; blk < num_blocks; blk = blk + 1) begin
            b_offset = blk * 1024;
            for (r = 0; r < 32; r = r + 1)
                process_1d_burst(KEY_ENC, 0, 1, b_offset + r*32, 1, b_offset + r*32);
        end
        fd_out = $fopen(`FENC1D, "w");
        for (i = 0; i < total_pixels; i = i + 1)
            $fwrite(fd_out, "%02X %02X\n", mem_b[i][15:8], mem_b[i][7:0]);
        $fclose(fd_out);

        $display("encrypt cols (2D)");
        for (blk = 0; blk < num_blocks; blk = blk + 1) begin
            b_offset = blk * 1024;
            for (c = 0; c < 32; c = c + 1)
                process_1d_burst(KEY_ENC, 1, 32, b_offset + c, 32, b_offset + c);
        end
        fd_out = $fopen(`FENC2D, "w");
        for (i = 0; i < total_pixels; i = i + 1)
            $fwrite(fd_out, "%02X %02X\n", mem_a[i][15:8], mem_a[i][7:0]);
        $fclose(fd_out);

        $display("decrypt cols (1D)");
        for (blk = 0; blk < num_blocks; blk = blk + 1) begin
            b_offset = blk * 1024;
            for (c = 0; c < 32; c = c + 1)
                process_1d_burst(KEY_DEC, 0, 32, b_offset + c, 32, b_offset + c);
        end
        fd_out = $fopen(`FDEC1D, "w");
        for (i = 0; i < total_pixels; i = i + 1)
            $fwrite(fd_out, "%02X %02X\n", mem_b[i][15:8], mem_b[i][7:0]);
        $fclose(fd_out);

        $display("decrypt rows (2D)");
        for (blk = 0; blk < num_blocks; blk = blk + 1) begin
            b_offset = blk * 1024;
            for (r = 0; r < 32; r = r + 1)
                process_1d_burst(KEY_DEC, 1, 1, b_offset + r*32, 1, b_offset + r*32);
        end
        fd_out = $fopen(`FDEC2D, "w");
        for (i = 0; i < total_pixels; i = i + 1)
            $fwrite(fd_out, "%02X %02X\n", mem_a[i][15:8], mem_a[i][7:0]);
        $fclose(fd_out);

        $display("DONE");
        $finish;
    end

    initial begin
        #(`CYCLE * `MAX_CYCLE);
        $display("Time out");
        $finish;
    end
endmodule
