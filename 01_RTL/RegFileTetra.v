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
*     There is 4 banks, each bank supports 1 read & 1 write
* Review History:
*     2026.05.02    Guan-Yi Tsen
*********************************************************************/

module RegFileTetra #(
    parameter DATA_WIDTH = 33,
    parameter REG_DEPTH  = 32,
    parameter REG_ADDRW  = 5
)(
    input                       clk, rst_n,
    input       [REG_ADDRW-1:0] read_addr_1, read_addr_2, read_addr_3, read_addr_4,
    output reg [DATA_WIDTH-1:0] read_data_1, read_data_2, read_data_3, read_data_4,

    input                       wen1, wen2, wen3, wen4,
    input       [REG_ADDRW-1:0] write_addr_1, write_addr_2, write_addr_3, write_addr_4,
    input      [DATA_WIDTH-1:0] write_data_1, write_data_2, write_data_3, write_data_4
);

    // ====================================================================
    // 1. Address Mapping Function (Perfect Conflict-Free for N=32 Dual-BFU)
    // ====================================================================
    function [4:0] get_physical_addr;
        input [4:0] logical_addr;
        reg   [1:0] bank_id;
        reg   [2:0] bank_addr;
        begin
            // 完美無衝突 XOR Mapping (完全覆蓋 FNT 與 IFNT 特性)
            bank_id[0] = logical_addr[0] ^ logical_addr[1] ^ logical_addr[2] ^ logical_addr[3];
            bank_id[1] = logical_addr[0] ^ logical_addr[4];
            
            // Bank 內的位址，確保同 Bank 內的 8 個元素位址唯一
            bank_addr  = {logical_addr[4], logical_addr[3], logical_addr[2]};
            
            get_physical_addr = {bank_id, bank_addr};
        end
    endfunction

    // ====================================================================
    // 2. Physical Memory Banks (4 x Depth 8)
    // ====================================================================
    reg  [DATA_WIDTH-1:0] bank_mem_0 [0:7];
    reg  [DATA_WIDTH-1:0] bank_mem_1 [0:7];
    reg  [DATA_WIDTH-1:0] bank_mem_2 [0:7];
    reg  [DATA_WIDTH-1:0] bank_mem_3 [0:7];

    // Internal signals for banks
    reg  [2:0]  bank_raddr [0:3];
    reg  [2:0]  bank_waddr [0:3];
    reg  [DATA_WIDTH-1:0] bank_wdata [0:3];
    reg         bank_wen   [0:3];
    wire [DATA_WIDTH-1:0] bank_rdata [0:3];

    // Read Data (Combinational read from memory array)
    assign bank_rdata[0] = bank_mem_0[bank_raddr[0]];
    assign bank_rdata[1] = bank_mem_1[bank_raddr[1]];
    assign bank_rdata[2] = bank_mem_2[bank_raddr[2]];
    assign bank_rdata[3] = bank_mem_3[bank_raddr[3]];

    // Write Logic (Synchronous)
    always @(posedge clk) begin
        if (bank_wen[0]) bank_mem_0[bank_waddr[0]] <= bank_wdata[0];
        if (bank_wen[1]) bank_mem_1[bank_waddr[1]] <= bank_wdata[1];
        if (bank_wen[2]) bank_mem_2[bank_waddr[2]] <= bank_wdata[2];
        if (bank_wen[3]) bank_mem_3[bank_waddr[3]] <= bank_wdata[3];
    end

    // ====================================================================
    // 3. Read Crossbar (Dispatching Addresses & Collecting Data)
    // ====================================================================
    wire [4:0] p_raddr_1 = get_physical_addr(read_addr_1);
    wire [4:0] p_raddr_2 = get_physical_addr(read_addr_2);
    wire [4:0] p_raddr_3 = get_physical_addr(read_addr_3);
    wire [4:0] p_raddr_4 = get_physical_addr(read_addr_4);

    always @(*) begin
        // Bank 0 的 Address 選擇
        if      (p_raddr_1[4:3] == 2'd0) bank_raddr[0] = p_raddr_1[2:0];
        else if (p_raddr_2[4:3] == 2'd0) bank_raddr[0] = p_raddr_2[2:0];
        else if (p_raddr_3[4:3] == 2'd0) bank_raddr[0] = p_raddr_3[2:0];
        else                             bank_raddr[0] = p_raddr_4[2:0]; 

        // Bank 1 的 Address 選擇
        if      (p_raddr_1[4:3] == 2'd1) bank_raddr[1] = p_raddr_1[2:0];
        else if (p_raddr_2[4:3] == 2'd1) bank_raddr[1] = p_raddr_2[2:0];
        else if (p_raddr_3[4:3] == 2'd1) bank_raddr[1] = p_raddr_3[2:0];
        else                             bank_raddr[1] = p_raddr_4[2:0];

        // Bank 2 的 Address 選擇
        if      (p_raddr_1[4:3] == 2'd2) bank_raddr[2] = p_raddr_1[2:0];
        else if (p_raddr_2[4:3] == 2'd2) bank_raddr[2] = p_raddr_2[2:0];
        else if (p_raddr_3[4:3] == 2'd2) bank_raddr[2] = p_raddr_3[2:0];
        else                             bank_raddr[2] = p_raddr_4[2:0];

        // Bank 3 的 Address 選擇
        if      (p_raddr_1[4:3] == 2'd3) bank_raddr[3] = p_raddr_1[2:0];
        else if (p_raddr_2[4:3] == 2'd3) bank_raddr[3] = p_raddr_2[2:0];
        else if (p_raddr_3[4:3] == 2'd3) bank_raddr[3] = p_raddr_3[2:0];
        else                             bank_raddr[3] = p_raddr_4[2:0];
    end

    // // Pipeline Register for Read Data (Timing Optimization)
    // always @(posedge clk or negedge rst_n) begin
    //     if (!rst_n) begin
    //         read_data_1 <= 0; read_data_2 <= 0;
    //         read_data_3 <= 0; read_data_4 <= 0;
    //     end else begin
    //         // Fetch the output data based on the original Bank ID mapping
    //         read_data_1 <= bank_rdata[p_raddr_1[4:3]];
    //         read_data_2 <= bank_rdata[p_raddr_2[4:3]];
    //         read_data_3 <= bank_rdata[p_raddr_3[4:3]];
    //         read_data_4 <= bank_rdata[p_raddr_4[4:3]];
    //     end
    // end

    always @(*) begin
        read_data_1 = bank_rdata[p_raddr_1[4:3]];
        read_data_2 = bank_rdata[p_raddr_2[4:3]];
        read_data_3 = bank_rdata[p_raddr_3[4:3]];
        read_data_4 = bank_rdata[p_raddr_4[4:3]];
    end

    // ====================================================================
    // 4. Write Crossbar (Dispatching Data and Enables)
    // ====================================================================
    wire [4:0] p_waddr_1 = get_physical_addr(write_addr_1);
    wire [4:0] p_waddr_2 = get_physical_addr(write_addr_2);
    wire [4:0] p_waddr_3 = get_physical_addr(write_addr_3);
    wire [4:0] p_waddr_4 = get_physical_addr(write_addr_4);

    always @(*) begin
        // Default assignments to avoid latches
        bank_wen[0] = 1'b0; bank_waddr[0] = 3'b0; bank_wdata[0] = 0;
        bank_wen[1] = 1'b0; bank_waddr[1] = 3'b0; bank_wdata[1] = 0;
        bank_wen[2] = 1'b0; bank_waddr[2] = 3'b0; bank_wdata[2] = 0;
        bank_wen[3] = 1'b0; bank_waddr[3] = 3'b0; bank_wdata[3] = 0;

        // Route Enables, Addresses, and Data
        if (wen1) begin
            bank_wen  [p_waddr_1[4:3]] = 1'b1;
            bank_waddr[p_waddr_1[4:3]] = p_waddr_1[2:0];
            bank_wdata[p_waddr_1[4:3]] = write_data_1;
        end
        if (wen2) begin
            bank_wen  [p_waddr_2[4:3]] = 1'b1;
            bank_waddr[p_waddr_2[4:3]] = p_waddr_2[2:0];
            bank_wdata[p_waddr_2[4:3]] = write_data_2;
        end
        if (wen3) begin
            bank_wen  [p_waddr_3[4:3]] = 1'b1;
            bank_waddr[p_waddr_3[4:3]] = p_waddr_3[2:0];
            bank_wdata[p_waddr_3[4:3]] = write_data_3;
        end
        if (wen4) begin
            bank_wen  [p_waddr_4[4:3]] = 1'b1;
            bank_waddr[p_waddr_4[4:3]] = p_waddr_4[2:0];
            bank_wdata[p_waddr_4[4:3]] = write_data_4;
        end
    end

endmodule
/*
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
*/