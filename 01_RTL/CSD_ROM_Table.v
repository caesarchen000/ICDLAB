`timescale 1ns/1ps

module CSD_ROM_Table_even (
    input  wire [4:0] n_idx,  input  wire [4:0] k_idx,
    output reg  [1:0] sign1,  output reg  [3:0] shift1,
    output reg  [1:0] sign2,  output reg  [3:0] shift2,
    output reg  [1:0] sign3,  output reg  [3:0] shift3
);

    always @(*) begin
        sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0;

        case (k_idx)
            5'd0: begin
                case (n_idx)
                    5'd00: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd01: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd3; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd3; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd1: begin
                case (n_idx)
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd2: begin
                case (n_idx)
                    5'd00: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd1; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd1; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd3: begin
                case (n_idx)
                    5'd02: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd20: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b00; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd4: begin
                case (n_idx)
                    5'd00: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd01: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd02: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd4; sign2 = 2'b00; shift2 = 4'd3; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd4; sign2 = 2'b00; shift2 = 4'd3; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd5: begin
                case (n_idx)
                    5'd02: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd08: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd14: begin sign1 = 2'b01; shift1 = 4'd2; sign2 = 2'b01; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd2; sign2 = 2'b00; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd6: begin
                case (n_idx)
                    5'd00: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd01: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd04: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd4; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd2; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd16: begin sign1 = 2'b00; shift1 = 4'd1; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd2; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd4; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd7: begin
                case (n_idx)
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd04: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd20: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd8: begin
                case (n_idx)
                    5'd00: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd02: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd16: begin sign1 = 2'b00; shift1 = 4'd4; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd9: begin
                case (n_idx)
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd04: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd08: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd14: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd5; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd10: begin
                case (n_idx)
                    5'd00: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd01: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd16: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd11: begin
                case (n_idx)
                    5'd02: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd14: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd12: begin
                case (n_idx)
                    5'd00: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd04: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd08: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd4; sign2 = 2'b00; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd16: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd4; sign2 = 2'b00; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd13: begin
                case (n_idx)
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd14: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd14: begin
                case (n_idx)
                    5'd00: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd04: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd14: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd15: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd16: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd17: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd20: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd15: begin
                case (n_idx)
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd20: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd16: begin
                case (n_idx)
                    5'd00: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd16: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd23: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd17: begin
                case (n_idx)
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd08: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd14: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd18: begin
                case (n_idx)
                    5'd00: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd01: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd02: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd04: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd16: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd20: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd19: begin
                case (n_idx)
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd08: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd6; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd20: begin
                case (n_idx)
                    5'd00: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd4; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd08: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd16: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd20: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd4; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd21: begin
                case (n_idx)
                    5'd02: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd04: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd08: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd22: begin
                case (n_idx)
                    5'd00: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd15: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd16: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd17: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd23: begin
                case (n_idx)
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b00; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd24: begin
                case (n_idx)
                    5'd00: begin sign1 = 2'b00; shift1 = 4'd4; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd5; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd14: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd16: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd23: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd5; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd25: begin
                case (n_idx)
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd2; sign2 = 2'b00; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd2; sign2 = 2'b01; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd26: begin
                case (n_idx)
                    5'd00: begin sign1 = 2'b01; shift1 = 4'd1; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd01: begin sign1 = 2'b00; shift1 = 4'd2; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd02: begin sign1 = 2'b01; shift1 = 4'd4; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd04: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd08: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd14: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd16: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd4; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd2; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd27: begin
                case (n_idx)
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd14: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd20: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b00; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd28: begin
                case (n_idx)
                    5'd02: begin sign1 = 2'b01; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd04: begin sign1 = 2'b01; shift1 = 4'd4; sign2 = 2'b01; shift2 = 4'd3; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd08: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd16: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd20: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd4; sign2 = 2'b01; shift2 = 4'd3; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd29: begin
                case (n_idx)
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd20: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd30: begin
                case (n_idx)
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd1; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd16: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd23: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd1; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd31: begin
                case (n_idx)
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd3; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd16: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd3; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
        endcase
    end
endmodule

module CSD_ROM_Table_odd (
    input  wire [4:0] n_idx,  input  wire [4:0] k_idx,
    output reg  [1:0] sign1,  output reg  [3:0] shift1,
    output reg  [1:0] sign2,  output reg  [3:0] shift2,
    output reg  [1:0] sign3,  output reg  [3:0] shift3
);

    always @(*) begin
        sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0;

        case (k_idx)
            5'd0: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd1: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd1; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd1; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd23: begin sign1 = 2'b01; shift1 = 4'd5; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd2: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd3: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd02: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd1; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd1; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd20: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b00; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd5; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd23: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd3; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd4: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd5: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd02: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd08: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd4; sign2 = 2'b01; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd14: begin sign1 = 2'b01; shift1 = 4'd2; sign2 = 2'b01; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd15: begin sign1 = 2'b01; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd2; sign2 = 2'b00; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd4; sign2 = 2'b00; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd6: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd2; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd2; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd7: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd04: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b00; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd17: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd20: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd23: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd8: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd9: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd04: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd08: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd14: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd15: begin sign1 = 2'b01; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd10: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd11: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd02: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd14: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd15: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd3; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd3; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd12: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd4; sign2 = 2'b00; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd4; sign2 = 2'b00; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd13: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd14: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd15: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd23: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd14: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd15: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd17: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd15: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd10: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd17: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd20: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd16: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd23: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd17: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd08: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd14: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd15: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd4; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd18: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd19: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd3; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd08: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd17: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd23: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd3; sign3 = 2'b01; shift3 = 4'd1; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd20: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd4; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd4; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd21: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd02: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd04: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd06: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd08: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd17: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd28: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd30: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd22: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd15: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd17: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd23: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd17: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b00; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd24: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd5; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd23: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd29: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd31: begin sign1 = 2'b01; shift1 = 4'd5; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd25: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b01; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd02: begin sign1 = 2'b00; shift1 = 4'd2; sign2 = 2'b00; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd4; sign2 = 2'b01; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd12: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd13: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd15: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd4; sign2 = 2'b00; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd30: begin sign1 = 2'b01; shift1 = 4'd2; sign2 = 2'b01; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd26: begin
                case (n_idx)
                    5'd01: begin sign1 = 2'b00; shift1 = 4'd2; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd9; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd1; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd9; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd31: begin sign1 = 2'b00; shift1 = 4'd2; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd27: begin
                case (n_idx)
                    5'd03: begin sign1 = 2'b01; shift1 = 4'd1; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd04: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd5; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd14: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd17: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd20: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd2; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd3; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd2; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd28: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b00; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd1; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd28: begin
                case (n_idx)
                    5'd03: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd05: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd07: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd09: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd11: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd9; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd6; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd29: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b01; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd29: begin
                case (n_idx)
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd1; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd5; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd7; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd8; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd10; sign2 = 2'b01; shift2 = 4'd6; sign3 = 2'b00; shift3 = 4'd4; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd15: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd9; sign3 = 2'b01; shift3 = 4'd7; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd9; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd18: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd8; end
                    5'd19: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b01; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd20: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd21: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd22: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd6; sign3 = 2'b01; shift3 = 4'd4; end
                    5'd23: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd7; sign3 = 2'b01; shift3 = 4'd5; end
                    5'd24: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd0; end
                    5'd25: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd26: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd27: begin sign1 = 2'b00; shift1 = 4'd1; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd30: begin
                case (n_idx)
                    5'd05: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd15: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd17: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd7; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd11; sign3 = 2'b00; shift3 = 4'd6; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd2; end
                    5'd23: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b00; shift3 = 4'd0; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd7; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd27: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
            5'd31: begin
                case (n_idx)
                    5'd06: begin sign1 = 2'b00; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd07: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b00; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd08: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd3; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd09: begin sign1 = 2'b01; shift1 = 4'd6; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd10: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd11: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd12: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd13: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd14: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd15: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd16: begin sign1 = 2'b00; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd5; sign3 = 2'b01; shift3 = 4'd2; end
                    5'd17: begin sign1 = 2'b01; shift1 = 4'd13; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd18: begin sign1 = 2'b00; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b00; shift3 = 4'd9; end
                    5'd19: begin sign1 = 2'b01; shift1 = 4'd12; sign2 = 2'b00; shift2 = 4'd10; sign3 = 2'b01; shift3 = 4'd8; end
                    5'd20: begin sign1 = 2'b00; shift1 = 4'd11; sign2 = 2'b01; shift2 = 4'd8; sign3 = 2'b01; shift3 = 4'd6; end
                    5'd21: begin sign1 = 2'b01; shift1 = 4'd10; sign2 = 2'b00; shift2 = 4'd8; sign3 = 2'b00; shift3 = 4'd5; end
                    5'd22: begin sign1 = 2'b00; shift1 = 4'd8; sign2 = 2'b00; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd1; end
                    5'd23: begin sign1 = 2'b01; shift1 = 4'd6; sign2 = 2'b01; shift2 = 4'd4; sign3 = 2'b01; shift3 = 4'd3; end
                    5'd24: begin sign1 = 2'b00; shift1 = 4'd5; sign2 = 2'b01; shift2 = 4'd3; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd25: begin sign1 = 2'b01; shift1 = 4'd3; sign2 = 2'b00; shift2 = 4'd1; sign3 = 2'b10; shift3 = 4'd0; end
                    5'd26: begin sign1 = 2'b00; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                    default: begin sign1 = 2'b10; shift1 = 4'd0; sign2 = 2'b10; shift2 = 4'd0; sign3 = 2'b10; shift3 = 4'd0; end
                endcase
            end
        endcase
    end
endmodule

