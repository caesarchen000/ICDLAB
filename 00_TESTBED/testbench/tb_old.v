module tb;

    reg clk;
    reg rst_n;
    reg start;
    reg in_valid;
    reg signed [7:0] data_in_r;
    reg signed [7:0] data_in_i;
    reg [7:0] key;
    
    wire finish;
    wire out_valid;
    wire signed [7:0] data_out_r;
    wire signed [7:0] data_out_i;

    CHIP u_chip (
        .clk(clk), .rst_n(rst_n), .start(start), .finish(finish),
        .in_valid(in_valid), .data_in_r(data_in_r), .data_in_i(data_in_i),
        .key(key), .out_valid(out_valid),
        .data_out_r(data_out_r), .data_out_i(data_out_i)
    );

    reg [7:0] mem_in_r [0:31];
    reg [7:0] mem_in_i [0:31];
    reg [7:0] gold_hw_r [0:31];
    reg [7:0] gold_hw_i [0:31];
    reg [63:0] gold_th_r [0:31]; 
    reg [63:0] gold_th_i [0:31];

    integer i, error_cnt, fd_in, fd_gold, code;

    always #5 clk = ~clk;

    initial begin
        fd_in   = $fopen("../00_TESTBED/pattern/input.txt", "r");
        fd_gold = $fopen("../00_TESTBED/pattern/golden.txt", "r");
        if (fd_in == 0 || fd_gold == 0) begin
            $display("Error: Cannot open files");
            $finish;
        end

        for (i = 0; i < 32; i = i + 1) begin
            code = $fscanf(fd_in, "%h %h\n", mem_in_r[i], mem_in_i[i]);
            code = $fscanf(fd_gold, "%h %h %h %h\n", gold_hw_r[i], gold_hw_i[i], gold_th_r[i], gold_th_i[i]);
        end
        $fclose(fd_in); $fclose(fd_gold);

        clk = 0; rst_n = 1; start = 0; in_valid = 0;
        data_in_r = 0; data_in_i = 0; key = 8'd64; error_cnt = 0;

        #15 rst_n = 0;
        #20 rst_n = 1;
        #10;

        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;

        // 寫入 32 筆資料
        for (i = 0; i < 32; i = i + 1) begin
            in_valid = 1;
            data_in_r = mem_in_r[i];
            data_in_i = mem_in_i[i];
            @(negedge clk);
        end
        in_valid = 0;

        $display("Data loaded. Waiting for hardware to compute and output...");

        // 直接等待輸出結果，收集 32 筆
        for (i = 0; i < 32; i = i + 1) begin
            wait(out_valid == 1'b1);
            @(negedge clk); // 在波谷檢查資料最穩定
            
            if (data_out_r !== gold_hw_r[i] || data_out_i !== gold_hw_i[i]) begin
                $display("Mismatch at %2d: HW=(%02x, %02x), Gold=(%02x, %02x)", 
                          i, data_out_r & 8'hFF, data_out_i & 8'hFF, gold_hw_r[i], gold_hw_i[i]);
                error_cnt = error_cnt + 1;
            end
        end

        // 確認硬體正常拉高 finish
        wait(finish == 1'b1);

        if (error_cnt == 0) begin
            $display("\n========================================");
            $display("              SIMULATION PASSED         ");
            $display("========================================\n");
        end else begin
            $display("\n========================================");
            $display("      SIMULATION FAILED with %d errors  ", error_cnt);
            $display("========================================\n");
        end
        $finish;
    end
    
    initial begin
        $fsdbDumpfile("DFrFT.fsdb");
        $fsdbDumpvars(0, tb, "+mda");
    end

	initial begin	// ! Time Limitation Exceeded
		// calculate clock cycles for all operation (you can modify it)
		#(100000)
        $display("Time out");
	 	$finish;
	end

endmodule