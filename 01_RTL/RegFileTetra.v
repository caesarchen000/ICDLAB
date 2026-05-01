/********************************************************************
* Filename: RegFileTetra.v
* Authors:
*     Guan-Yi Tsen
* Description:
*     Register File
* Parameters:
*     DATA_WIDTH : data width
*     REG_DEPTH  : how many words in reg file
*     REG_ADDRW  : reg data address width
* Note:
*     It contains 32 words with 33 bits
*     Support dual port read & write
* Review History:
*     2026.04.18    Guan-Yi Tsen
*********************************************************************/

module RegFileTetra #(
    parameter DATA_WIDTH = 33,
    parameter REG_DEPTH  = 32,
    parameter REG_ADDRW  = 5
)(
    input                       clk,
    input       [REG_ADDRW-1:0] read_addr_1, read_addr_2, read_addr_3, read_addr_4,
    output reg [DATA_WIDTH-1:0] read_data_1, read_data_2, read_data_3, read_data_4,

    input                       wen1, wen2, wen3, wen4,
    input       [REG_ADDRW-1:0] write_addr_1, write_addr_2, write_addr_3, write_addr_4,
    input      [DATA_WIDTH-1:0] write_data_1, write_data_2, write_data_3, write_data_4
);
    reg [DATA_WIDTH-1:0] reg_array [0:REG_DEPTH-1];

    always @(*) begin
        read_data_1 = reg_array[read_addr_1];
        read_data_2 = reg_array[read_addr_2];
        read_data_3 = reg_array[read_addr_3];
        read_data_4 = reg_array[read_addr_4];
    end

    always @(posedge clk) begin
        if(wen1) reg_array[write_addr_1] <= write_data_1;
        if(wen2) reg_array[write_addr_2] <= write_data_2;
        if(wen3) reg_array[write_addr_3] <= write_data_3;
        if(wen4) reg_array[write_addr_4] <= write_data_4;
    end
endmodule
