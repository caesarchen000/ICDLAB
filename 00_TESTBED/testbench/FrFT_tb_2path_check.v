`timescale 1ns/1ps

module FrFT_tb_2path_check;
    parameter CLK_PERIOD = 10;

    reg clk, rst_n, i_valid, o_ready, i_mode;
    reg [15:0] i_data;
    wire i_ready, o_valid;
    wire [7:0] o_data;

    integer rx_bytes;
    integer err_cnt;
    integer word_idx;
    reg [7:0] exp_byte;

    FrFT_stream_2path dut (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid(i_valid),
        .i_ready(i_ready),
        .o_ready(o_ready),
        .o_valid(o_valid),
        .i_mode(i_mode),
        .i_data(i_data),
        .o_data(o_data)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    task send_frame;
        input mode_path;
        input [7:0] key;
        integer k;
        begin
            // beat 0: key
            wait(i_ready == 1'b1); @(negedge clk);
            i_mode = mode_path;
            i_data = {8'b0, key};
            i_valid = 1'b1;
            @(posedge clk);

            // beat 1~2: preamble
            wait(i_ready == 1'b1); @(negedge clk); i_data = 16'hA55A; @(posedge clk);
            wait(i_ready == 1'b1); @(negedge clk); i_data = 16'h5AA5; @(posedge clk);

            // beat 3~34: payload (32 samples)
            for (k = 0; k < 32; k = k + 1) begin
                wait(i_ready == 1'b1); @(negedge clk);
                i_data = {k[7:0], (8'hFF - k[7:0])};
                @(posedge clk);
            end
            @(negedge clk); i_valid = 1'b0; @(posedge clk);
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 1;
        i_valid = 0;
        o_ready = 0;
        i_mode = 0;
        i_data = 0;
        #(CLK_PERIOD*2) rst_n = 0;
        #(CLK_PERIOD*2) rst_n = 1;
        #(CLK_PERIOD*2);

        // Current stream wrapper consumes one frame per run.
        send_frame(1'b0, 8'd50);

        // Receive one combined output frame: 132 bytes
        o_ready = 1'b1;
        rx_bytes = 0;
        err_cnt = 0;
        while (rx_bytes < 132) begin
            wait(o_valid == 1'b1);
            @(posedge clk);
            if (rx_bytes < 4) begin
                case (rx_bytes[1:0])
                    2'd0: exp_byte = 8'hA5;
                    2'd1: exp_byte = 8'h5A;
                    2'd2: exp_byte = 8'h5A;
                    default: exp_byte = 8'hA5;
                endcase
            end else begin
                word_idx = (rx_bytes - 4) >> 2;
                case (rx_bytes[1:0])
                    2'd0: exp_byte = dut.u_pipe.out_mem[word_idx][31:24];
                    2'd1: exp_byte = dut.u_pipe.out_mem[word_idx][23:16];
                    2'd2: exp_byte = dut.u_pipe.out_mem[word_idx][15:8];
                    default: exp_byte = dut.u_pipe.out_mem[word_idx][7:0];
                endcase
            end

            if (o_data !== exp_byte) begin
                $display("BYTE MISMATCH at byte=%0d got=%02h exp=%02h", rx_bytes, o_data, exp_byte);
                err_cnt = err_cnt + 1;
            end
            rx_bytes = rx_bytes + 1;
        end
        o_ready = 1'b0;

        if (err_cnt == 0) begin
            $display("2PATH STREAM VALUE CHECK PASS: 132-byte frame matches expected stream packing.");
        end else begin
            $display("2PATH STREAM VALUE CHECK FAIL: err_cnt=%0d", err_cnt);
        end

        $finish;
    end

    // Safety timeout for deadlock diagnosis
    initial begin
        #(CLK_PERIOD * 400000);
        $display("2PATH STREAM CHECK TIMEOUT: no completed output frame.");
        $display("debug: state=%0d in_beat=%0d out_byte=%0d pipe_busy=%0d pipe_done=%0d",
            dut.state_r, dut.in_beat_r, dut.out_byte_r, dut.pipe_busy, dut.pipe_done);
        $finish;
    end

endmodule

