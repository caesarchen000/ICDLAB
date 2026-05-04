/********************************************************************
* Filename: RegFileDual.v
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
*     There is 2 banks, each bank supports 1 read & 1 write
*     synchronous read (read will delay 1 cycle)
* Review History:
*     2026.05.03    Guan-Yi Tsen
*********************************************************************/

module RegFileDual #(
    parameter DATA_WIDTH = 33,
    parameter REG_DEPTH  = 32,
    parameter REG_ADDRW  = 5
)(
    input                       clk, rst_n,
    input       [REG_ADDRW-1:0] read_addr_1, read_addr_2,
    output reg [DATA_WIDTH-1:0] read_data_1, read_data_2,

    input                       wen1, wen2,
    input       [REG_ADDRW-1:0] write_addr_1, write_addr_2,
    input      [DATA_WIDTH-1:0] write_data_1, write_data_2
    );

    // ====================================================================
    // 1. Address Mapping Function
    // ====================================================================
    function [4:0] get_physical_addr;
        input [4:0] logical_addr;
        reg         bank_id;
        reg   [3:0] bank_addr;
        begin
            bank_id   = ^logical_addr;
            bank_addr = logical_addr[4:1]; 
            
            get_physical_addr = {bank_id, bank_addr}; // [4] = Bank, [3:0] = Addr
        end
    endfunction

    // ====================================================================
    // 2. Physical Memory Banks (2 x Depth 16)
    // ====================================================================
    reg  [DATA_WIDTH-1:0] bank_mem_0 [0:15];
    reg  [DATA_WIDTH-1:0] bank_mem_1 [0:15];

    // Internal signals for banks
    reg  [3:0]  bank_raddr [0:1];
    reg  [3:0]  bank_waddr [0:1];
    reg  [DATA_WIDTH-1:0] bank_wdata [0:1];
    reg         bank_wen   [0:1];
    wire [DATA_WIDTH-1:0] bank_rdata [0:1];

    // Read Data (Combinational read from memory array)
    assign bank_rdata[0] = bank_mem_0[bank_raddr[0]];
    assign bank_rdata[1] = bank_mem_1[bank_raddr[1]];

    // Write Logic (Synchronous)
    always @(posedge clk) begin
        if (bank_wen[0]) bank_mem_0[bank_waddr[0]] <= bank_wdata[0];
        if (bank_wen[1]) bank_mem_1[bank_waddr[1]] <= bank_wdata[1];
    end

    // ====================================================================
    // 3. Read Crossbar (Dispatching Addresses & Collecting Data)
    // ====================================================================
    wire [4:0] p_raddr_1 = get_physical_addr(read_addr_1);
    wire [4:0] p_raddr_2 = get_physical_addr(read_addr_2);

    always @(*) begin
        // Bank 0 的 Address 選擇
        if      (p_raddr_1[4] == 1'd0) bank_raddr[0] = p_raddr_1[3:0];
        else                           bank_raddr[0] = p_raddr_2[3:0]; 

        // Bank 1 的 Address 選擇
        if      (p_raddr_1[4] == 1'd1) bank_raddr[1] = p_raddr_1[3:0];
        else                           bank_raddr[1] = p_raddr_2[3:0];

    end

    // Pipeline Register for Read Data (Timing Optimization)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data_1 <= 0; read_data_2 <= 0;
        end else begin
            // Fetch the output data based on the original Bank ID mapping
            read_data_1 <= bank_rdata[p_raddr_1[4]];
            read_data_2 <= bank_rdata[p_raddr_2[4]];
        end
    end

    // always @(*) begin
    //     read_data_1 = bank_rdata[p_raddr_1[4]];
    //     read_data_2 = bank_rdata[p_raddr_2[4]];
    // end

    // ====================================================================
    // 4. Write Crossbar (Dispatching Data and Enables)
    // ====================================================================
    wire [4:0] p_waddr_1 = get_physical_addr(write_addr_1);
    wire [4:0] p_waddr_2 = get_physical_addr(write_addr_2);

    always @(*) begin
        // Default assignments to avoid latches
        bank_wen[0] = 0; bank_waddr[0] = 0; bank_wdata[0] = 0;
        bank_wen[1] = 0; bank_waddr[1] = 0; bank_wdata[1] = 0;

        // Route Enables, Addresses, and Data
        if (wen1) begin
            bank_wen  [p_waddr_1[4]] = 1'b1;
            bank_waddr[p_waddr_1[4]] = p_waddr_1[3:0];
            bank_wdata[p_waddr_1[4]] = write_data_1;
        end
        if (wen2) begin
            bank_wen  [p_waddr_2[4]] = 1'b1;
            bank_waddr[p_waddr_2[4]] = p_waddr_2[3:0];
            bank_wdata[p_waddr_2[4]] = write_data_2;
        end
    end

endmodule

/*
module RegFileDual #(
    parameter DATA_WIDTH = 33,
    parameter REG_DEPTH  = 32,
    parameter REG_ADDRW  = 5
)(
    input                       clk,
    input       [REG_ADDRW-1:0] read_addr_1, read_addr_2,
    output reg [DATA_WIDTH-1:0] read_data_1, read_data_2,

    input                       wen1, wen2,
    input       [REG_ADDRW-1:0] write_addr_1, write_addr_2,
    input      [DATA_WIDTH-1:0] write_data_1, write_data_2
);
    reg [DATA_WIDTH-1:0] reg_array [0:REG_DEPTH-1];

    always @(*) begin
        read_data_1 = reg_array[read_addr_1];
        read_data_2 = reg_array[read_addr_2];
    end

    always @(posedge clk) begin
        if(wen1) reg_array[write_addr_1] <= write_data_1;
        if(wen2) reg_array[write_addr_2] <= write_data_2;
    end
endmodule
*/
