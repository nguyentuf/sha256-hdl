`default_nettype none
`timescale 1ns/1ps

module tb_sha256;

    reg          clk;
    reg          reset_n;
    reg  [7:0]   in_data;
    reg          valid_input;
    reg          lastbyte;
    wire         pad_ready;
    wire         hash_done;
    wire [255:0] digest;

    // --- B? ??M XUNG CLOCK (CLOCK COUNTER) ---
    integer clk_cnt;
    
    initial begin
        clk_cnt = 0;
    end
    
    always @(posedge clk) begin
        clk_cnt = clk_cnt + 1;
    end

    // --- KH?I T?O MODULE TOP ---
    sha256_top uut (
        .clk         (clk),
        .reset_n     (reset_n),
        .in_data     (in_data),
        .valid_input (valid_input),
        .lastbyte    (lastbyte),
        .pad_ready   (pad_ready),
        .hash_done   (hash_done),
        .digest      (digest)
    );

    // --- T?O XUNG NH?P ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // --- TASK T? ??NG B?M CHU?I ---
    // T?ng gi?i h?n m?ng lên 128 bytes (8*128-1:0) ?? ch?a chu?i siêu dài
    task test_string;
        input [8*128-1:0] str;           
        input integer     len;           
        input [255:0]     expected_hash; 
        
        integer i;
        reg [7:0] char;
        integer start_clk, end_clk;
        begin
            $display("=== DANG TEST CHUOI CO DO DAI %0d BYTE ===", len);
            
            // Ghi nh?n th?i ?i?m (s? clock) b?t ??u n?p d? li?u
            start_clk = clk_cnt;
            
            for (i = len; i > 0; i = i - 1) begin
                char = str[(i*8-1) -: 8]; 
                
                @(negedge clk);
                while (!pad_ready) @(negedge clk); 
                
                valid_input = 1'b1;
                in_data     = char;
                lastbyte    = (i == 1) ? 1'b1 : 1'b0; 
            end
            
            @(negedge clk);
            valid_input = 1'b0;
            lastbyte    = 1'b0;
            
            $display("-> Dang cho phan cung xu ly...");
            while (!hash_done) @(posedge clk);
            
            // Ghi nh?n th?i ?i?m tính xong
            end_clk = clk_cnt;
            
            // In k?t qu? ??i chi?u
            if (digest === expected_hash) begin
                $display("[PASS] Ma bam SHA-256 tao ra CHINH XAC!");
            end else begin
                $display("[FAIL] KET QUA KHONG KHOP!");
            end
            $display(" Ket qua thuc te: %x", digest);
            $display(" Ket qua ky vong: %x", expected_hash);
            
            // In s? clock ?ã tiêu t?n
            $display("-> Tong thoi gian xu ly: %0d chu ky xung nhip (clock cycles)", end_clk - start_clk);
            $display("------------------------------------------------\n");
            
            repeat(10) @(posedge clk);
        end
    endtask

    // --- K?CH B?N TEST ---
    initial begin
        reset_n     = 0;
        in_data     = 8'd0;
        valid_input = 0;
        lastbyte    = 0;

        $display("\n--- KHOI DONG HE THONG ---");
        repeat(5) @(posedge clk);
        reset_n = 1;
        repeat(5) @(posedge clk);

        // TEST CASE 1: 14 bytes (S? t?n 1 Block)
        test_string(
            "sha256hahahhaa", 
            14, 
            256'h084b5cf7c527978dfe098fe6a6ac0a8bb205b803fef250edd83271a8671aa674
        );

        // TEST CASE 2: 17 bytes (S? t?n 1 Block)
        test_string(
            "toilaconchotuitur", 
            17, 
            256'hb732b1df7676b834dbdfdbafff87c4645247dd1198bd44ad48d090827793174c
        );

        // TEST CASE 3 (New): 68 bytes (V??t 55 byte -> S? t? ??ng nh?y thành 2 Block)
        test_string(
            "toiiiiiiiiiiiiiiiiiiiiiiiiiiiiiajffajaifajijiacanccncanncancacandjdj", 
            68, 
            256'h715437eed892980dc970629ce58d3148b2b8c256066e455bf06136b1c4567467
        );

        $display("--- HOAN TAT KIEM TRA ---");
        $finish;
    end

endmodule