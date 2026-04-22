/********************************************************************
* Filename: RegFile.v
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

module RegFile #(
    parameter DATA_WIDTH = 33,
    parameter REG_DEPTH  = 32,
    parameter REG_ADDRW  = 5
)(
    input                       clk,
    input       [REG_ADDRW-1:0] read_addr_1,
    input       [REG_ADDRW-1:0] read_addr_2,
    output reg [DATA_WIDTH-1:0] read_data_1,
    output reg [DATA_WIDTH-1:0] read_data_2,

    input                       wen1,
    input                       wen2,
    input       [REG_ADDRW-1:0] write_addr_1,
    input       [REG_ADDRW-1:0] write_addr_2,
    input      [DATA_WIDTH-1:0] write_data_1,
    input      [DATA_WIDTH-1:0] write_data_2
);
    reg [DATA_WIDTH-1:0] reg_array [0:REG_DEPTH-1];

    always @(*) begin
        read_data_1 = reg_array[read_addr_1];
        read_data_2 = reg_array[read_addr_2];
    end

    always @(posedge clk) begin
        // dual port
        if(wen1) reg_array[write_addr_1] <= write_data_1;
        if(wen2) reg_array[write_addr_2] <= write_data_2;
    end
endmodule
