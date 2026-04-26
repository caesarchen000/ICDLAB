/********************************************************************
* Filename: FrFT_stream_2path.v
* Authors:
*   Yin-Liang Chen
* Description:
*   Streaming wrapper for FrFT_pipeline_2path.
*
* Function:
*   - Accept one input block by i_valid/i_ready:
*       beat0:  key
*       beat1:  preamble high16
*       beat2:  preamble low16
*       beat3..34: 32 payload samples (8+8 packed)
*   - Auto-start internal pipeline.
*   - Wait for done.
*   - Stream one output block by o_valid/o_ready:
*       4 preamble bytes + 128 payload bytes (32 x 32-bit words)
*********************************************************************/

module FrFT_stream_2path #(
    parameter KEY_WIDTH = 8
)(
    input              clk,
    input              rst_n,
    input              i_valid,
    output reg         i_ready,
    input              o_ready,
    output reg         o_valid,
    input              i_mode,         // kept for interface compatibility
    input      [15:0]  i_data,
    output reg [7:0]   o_data
);
    localparam S_IDLE   = 3'd0;
    localparam S_LOAD   = 3'd1;
    localparam S_START  = 3'd2;
    localparam S_WAIT   = 3'd3;
    localparam S_OUT    = 3'd4;

    reg [2:0]  state_r;
    reg [5:0]  in_beat_r;
    reg [7:0]  key_r;
    reg [31:0] preamble_r;

    reg        pipe_we_r;
    reg [4:0]  pipe_addr_r;
    reg [15:0] pipe_data_r;
    reg        pipe_start_r;
    wire       pipe_busy, pipe_done;
    reg  [4:0] pipe_out_addr_r;
    wire [31:0] pipe_out_data;

    reg [7:0] out_byte_r; // 0..131

    // i_mode is intentionally unused in this wrapper.
    wire _unused_i_mode = i_mode;

    FrFT_pipeline_2path #(
        .KEY_WIDTH(KEY_WIDTH),
        .N(32),
        .ADDRW(5)
    ) u_pipe (
        .clk(clk),
        .rst_n(rst_n),
        .in_we(pipe_we_r),
        .in_addr(pipe_addr_r),
        .in_data(pipe_data_r),
        .start(pipe_start_r),
        .key_alpha(key_r),
        .busy(pipe_busy),
        .done(pipe_done),
        .out_addr(pipe_out_addr_r),
        .out_data(pipe_out_data)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_r <= S_IDLE;
            in_beat_r <= 6'd0;
            key_r <= 8'd0;
            preamble_r <= 32'd0;
            pipe_we_r <= 1'b0;
            pipe_addr_r <= 5'd0;
            pipe_data_r <= 16'd0;
            pipe_start_r <= 1'b0;
            pipe_out_addr_r <= 5'd0;
            out_byte_r <= 8'd0;
            i_ready <= 1'b1;
            o_valid <= 1'b0;
            o_data <= 8'd0;
        end else begin
            pipe_we_r <= 1'b0;
            pipe_start_r <= 1'b0;
            i_ready <= 1'b0;
            o_valid <= 1'b0;

            case (state_r)
                S_IDLE: begin
                    i_ready <= 1'b1;
                    in_beat_r <= 6'd0;
                    if (i_valid) begin
                        // beat0: key
                        key_r <= i_data[7:0];
                        in_beat_r <= 6'd1;
                        state_r <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    i_ready <= 1'b1;
                    if (i_valid) begin
                        if (in_beat_r == 6'd1) begin
                            preamble_r[31:16] <= i_data;
                            in_beat_r <= 6'd2;
                        end else if (in_beat_r == 6'd2) begin
                            preamble_r[15:0] <= i_data;
                            in_beat_r <= 6'd3;
                        end else begin
                            // payload beats 3..34 -> preload addr 0..31
                            pipe_we_r <= 1'b1;
                            pipe_addr_r <= in_beat_r[4:0] - 5'd3;
                            pipe_data_r <= i_data;
                            if (in_beat_r == 6'd34) begin
                                state_r <= S_START;
                            end
                            in_beat_r <= in_beat_r + 1'b1;
                        end
                    end
                end

                S_START: begin
                    pipe_start_r <= 1'b1; // one-cycle pulse
                    state_r <= S_WAIT;
                end

                S_WAIT: begin
                    if (pipe_done) begin
                        out_byte_r <= 8'd0;
                        pipe_out_addr_r <= 5'd0;
                        state_r <= S_OUT;
                    end
                end

                S_OUT: begin
                    o_valid <= 1'b1;
                    if (out_byte_r < 8'd4) begin
                        case (out_byte_r[1:0])
                            2'd0: o_data <= preamble_r[31:24];
                            2'd1: o_data <= preamble_r[23:16];
                            2'd2: o_data <= preamble_r[15:8];
                            2'd3: o_data <= preamble_r[7:0];
                        endcase
                    end else begin
                        // payload bytes from pipeline readback
                        pipe_out_addr_r <= out_byte_r[6:2] - 5'd1;
                        case (out_byte_r[1:0])
                            2'd0: o_data <= pipe_out_data[31:24];
                            2'd1: o_data <= pipe_out_data[23:16];
                            2'd2: o_data <= pipe_out_data[15:8];
                            2'd3: o_data <= pipe_out_data[7:0];
                        endcase
                    end

                    if (o_ready) begin
                        if (out_byte_r == 8'd131) begin
                            state_r <= S_IDLE;
                        end
                        out_byte_r <= out_byte_r + 1'b1;
                    end
                end

                default: state_r <= S_IDLE;
            endcase
        end
    end

endmodule

