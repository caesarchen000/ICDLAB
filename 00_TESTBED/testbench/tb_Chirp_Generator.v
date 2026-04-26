`timescale 1ns/1ps

module tb_Chirp_Generator;

    // 參數定義
    parameter REG_ADDRW = 5;
    parameter KEY_WIDTH = 8;
    parameter DATA_WIDTH = 33;

    // 測試訊號宣告
    reg                      sel;
    reg                      conj;
    reg      [REG_ADDRW-1:0] idx;
    reg signed [KEY_WIDTH-1:0] key;
    wire     [DATA_WIDTH-1:0] out;

    // 檔案指標
    integer file_id;
    integer i, j, k;
    integer s, c, ii;   // ✅ loop 專用變數（關鍵）

    // 待測物實例化
    Chirp_Generator #(
        .REG_ADDRW(REG_ADDRW),
        .KEY_WIDTH(KEY_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .sel(sel),
        .conj(conj),
        .idx(idx),
        .key(key),
        .out(out)
    );

    // 測試密鑰
    integer test_keys[0:7];

    initial begin
        test_keys[0] = -127;
        test_keys[1] = -126;
        test_keys[2] = -64;
        test_keys[3] = -32;
        test_keys[4] = 0;
        test_keys[5] = 32;
        test_keys[6] = 64;
        test_keys[7] = 127;
    end

    initial begin
        // 開檔
        file_id = $fopen("Chirp_Output_Report.txt", "w");
        if (file_id == 0) begin
            $display("Error: Failed to open output file.");
            $finish;
        end

        $display("Start");

        // header
        $fdisplay(file_id, "=========================================================================");
        $fdisplay(file_id, "                    Chirp Generator Simulation Report                    ");
        $fdisplay(file_id, "=========================================================================");
        $fdisplay(file_id, " SEL | CONJ | IDX  |   KEY   ||       OUT (HEX)      |    OUT (DEC)      ");
        $fdisplay(file_id, "-------------------------------------------------------------------------");
        $display(" SEL | CONJ | IDX  |   KEY   ||       OUT (HEX)      |    OUT (DEC)      ");
        // 初始化
        sel = 0; conj = 0; idx = 0; key = 0;
        #10;

        // =========================
        // ✅ 修正後的 loop
        // =========================
        for (s = 0; s < 2; s = s + 1) begin
            sel = s;

            for (c = 0; c < 2; c = c + 1) begin
                conj = c;

                for (ii = 0; ii < 32; ii = ii + 8) begin
                    idx = ii[REG_ADDRW-1:0];  // ✅ 防 overflow

                    for (k = 0; k < 8; k = k + 1) begin
                        key = test_keys[k];
                        #10;

                        $display("  %b  |   %b  |  %2d  |  %4d  ||   33'h%09X   |   %10d  ", 
                                  sel, conj, idx, key, out, out);

                        $fdisplay(file_id, "  %b  |   %b  |  %2d  |  %4d  ||   33'h%09X   |   %10d  ", 
                                  sel, conj, idx, key, out, out);
                    end
                end

                // 邊界測試
                idx = 5'd16;
                key = 50;
                #10;

                $display("  %b  |   %b  |  %2d  |  %4d  ||   33'h%09X   |   %10d  ", 
                          sel, conj, idx, key, out, out);

                $fdisplay(file_id, "  %b  |   %b  |  %2d  |  %4d  ||   33'h%09X   |   %10d  ", 
                          sel, conj, idx, key, out, out);

                $fdisplay(file_id, "-------------------------------------------------------------------------");
            end
        end

        // =========================
        // 額外測試：k = 32
        // sel = 0,1 ; conj = 0 ; idx = 0~31
        // =========================
        $display("Extra Test: key = 32");
        $fdisplay(file_id, "Extra Test: key = 32");

        key = 32;
        conj = 0;

        for (s = 0; s < 2; s = s + 1) begin
            sel = s;

            for (ii = 0; ii < 32; ii = ii + 1) begin
                idx = ii[REG_ADDRW-1:0];
                #10;

                $display("  %b  |   %b  |  %2d  |  %4d  ||   33'h%09X   |   %10d  ", 
                          sel, conj, idx, key, out, out);

                $fdisplay(file_id, "  %b  |   %b  |  %2d  |  %4d  ||   33'h%09X   |   %10d  ", 
                          sel, conj, idx, key, out, out);
            end

            $fdisplay(file_id, "-------------------------------------------------------------------------");
        end

        // 結束
        $fdisplay(file_id, "=========================================================================");
        $fdisplay(file_id, "                              END OF REPORT                              ");
        $fdisplay(file_id, "=========================================================================");
        $fclose(file_id);

        $display("Simulation completed. Results written to Chirp_Output_Report.txt");
        $finish;
    end

endmodule