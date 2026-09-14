`default_nettype none
`timescale 1ns/1ps

module tb_sha256;

    // --- Khai báo tín hi?u k?t n?i ---
    reg          clk;
    reg          reset_n;
    reg  [7:0]   in_data;
    reg          valid_input;
    reg          lastbyte;
    wire         pad_ready;
    wire         hash_done;
    wire [255:0] digest;

    // --- Kh?i t?o DUT (Design Under Test) ---
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

    // --- T?o xung nh?p (Clock) 100MHz ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Chu k? 10ns
    end

    // --- Task t? ??ng b?m chu?i và ki?m tra k?t qu? ---
    // H? tr? chu?i dài t?i ?a 32 ký t? (ch?nh [8*32-1:0] n?u c?n dài h?n)
    task test_string;
        input [8*32-1:0] str;           // Chu?i d? li?u ??u vào
        input integer    len;           // ?? dài chu?i (s? l??ng byte)
        input [255:0]    expected_hash; // Mã b?m ?úng ?? ??i chi?u
        
        integer i;
        reg [7:0] char;
        begin
            $display("=== DANG TEST CHUOI CO DO DAI %0d BYTE ===", len);
            
            // Vòng l?p b?m t?ng byte vào m?ch
            for (i = len; i > 0; i = i - 1) begin
                char = str[(i*8-1) -: 8]; // Trích xu?t t?ng byte (t? trái qua ph?i)
                
                // ??a tín hi?u vào s??n xu?ng ?? tránh vi ph?m Setup/Hold time
                @(negedge clk);
                while (!pad_ready) @(negedge clk); // ??i m?ch ??m r?nh
                
                valid_input = 1'b1;
                in_data     = char;
                lastbyte    = (i == 1) ? 1'b1 : 1'b0; // B?t lastbyte n?u là byte cu?i
            end
            
            // Xóa c? ?i?u khi?n sau khi n?p xong
            @(negedge clk);
            valid_input = 1'b0;
            lastbyte    = 1'b0;
            
            // ??i ph?n c?ng b?m xong (c? hash_done b?t lên 1)
            $display("-> Dang cho phan cung xu ly (di qua Pipeline)...");
            while (!hash_done) @(posedge clk);
            
            // ?ã b?m xong, ti?n hành ??i chi?u
            if (digest === expected_hash) begin
                $display("[PASS] Ma bam SHA-256 tao ra CHINH XAC!");
                $display(" Ket qua: %x", digest);
            end else begin
                $display("[FAIL] KET QUA KHONG KHOP!");
                $display(" Mong doi: %x", expected_hash);
                $display(" Thuc te : %x", digest);
            end
            $display("------------------------------------------------\n");
            
            // Ngh? vài nh?p clock tr??c khi test chu?i ti?p theo
            repeat(10) @(posedge clk);
        end
    endtask

    // --- K?ch b?n Test (Test Scenario) ---
    initial begin
        // Kh?i t?o các tín hi?u v? 0
        reset_n     = 0;
        in_data     = 8'd0;
        valid_input = 0;
        lastbyte    = 0;

        // Reset h? th?ng
        $display("\n--- KHOI DONG HE THONG ---");
        repeat(5) @(posedge clk);
        reset_n = 1;
        repeat(5) @(posedge clk);

        // TEST CASE 1: "sha256hahahhaa" (14 bytes)
        test_string(
            "sha256hahahhaa", 
            14, 
            256'h084b5cf7c527978dfe098fe6a6ac0a8bb205b803fef250edd83271a8671aa674
        );

        // TEST CASE 2: "toilaconchotuitur" (17 bytes)
        test_string(
            "toilaconchotuitur", 
            17, 
            256'hb732b1df7676b834dbdfdbafff87c4645247dd1198bd44ad48d090827793174c
        );

        // K?t thúc mô ph?ng
        $display("--- HOAN TAT KIEM TRA ---");
        $finish;
    end

endmodule
