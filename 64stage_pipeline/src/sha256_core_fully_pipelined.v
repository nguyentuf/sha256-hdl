
module sha256_core_fully_pipelined(
    input  wire         clk,
    input  wire         reset_n,
    input  wire         valid_in,       
    input  wire [511:0] block_in,       
    input  wire [255:0] hash_init_in,   
    
    output wire         valid_out,      
    output wire [255:0] digest_out
    );
    wire [31:0] a_net [0:64]; wire [31:0] b_net [0:64]; wire [31:0] c_net [0:64]; wire [31:0] d_net [0:64];
    wire [31:0] e_net [0:64]; wire [31:0] f_net [0:64]; wire [31:0] g_net [0:64]; wire [31:0] h_net [0:64];
    
    wire [31:0] H0_net [0:64]; wire [31:0] H1_net [0:64]; wire [31:0] H2_net [0:64]; wire [31:0] H3_net [0:64];
    wire [31:0] H4_net [0:64]; wire [31:0] H5_net [0:64]; wire [31:0] H6_net [0:64]; wire [31:0] H7_net [0:64];
    wire [31:0] W_net [0:64][0:15];
    wire val_net[0:64];
    
    assign val_net[0] = valid_in;
    assign {a_net[0], b_net[0], c_net[0], d_net[0], e_net[0], f_net[0], g_net[0], h_net[0]} = hash_init_in;
    assign {H0_net[0], H1_net[0], H2_net[0], H3_net[0], H4_net[0], H5_net[0], H6_net[0], H7_net[0]} = hash_init_in;
  // xu ly w cao truoc w[0]=[512..]  
    genvar w;
       generate
        for (w = 0; w < 16; w = w + 1) begin : init_W
            assign W_net[0][15-w] = block_in[(w*32) +: 32];
        end
    endgenerate
    //K_constant
    wire [31:0] K_array [0:63];
    assign K_array[0]  = 32'h428a2f98; assign K_array[1]  = 32'h71374491;
    assign K_array[2]  = 32'hb5c0fbcf; assign K_array[3]  = 32'he9b5dba5;
    assign K_array[4]  = 32'h3956c25b; assign K_array[5]  = 32'h59f111f1;
    assign K_array[6]  = 32'h923f82a4; assign K_array[7]  = 32'hab1c5ed5;
    assign K_array[8]  = 32'hd807aa98; assign K_array[9]  = 32'h12835b01;
    assign K_array[10] = 32'h243185be; assign K_array[11] = 32'h550c7dc3;
    assign K_array[12] = 32'h72be5d74; assign K_array[13] = 32'h80deb1fe;
    assign K_array[14] = 32'h9bdc06a7; assign K_array[15] = 32'hc19bf174;
    assign K_array[16] = 32'he49b69c1; assign K_array[17] = 32'hefbe4786;
    assign K_array[18] = 32'h0fc19dc6; assign K_array[19] = 32'h240ca1cc;
    assign K_array[20] = 32'h2de92c6f; assign K_array[21] = 32'h4a7484aa;
    assign K_array[22] = 32'h5cb0a9dc; assign K_array[23] = 32'h76f988da;
    assign K_array[24] = 32'h983e5152; assign K_array[25] = 32'ha831c66d;
    assign K_array[26] = 32'hb00327c8; assign K_array[27] = 32'hbf597fc7;
    assign K_array[28] = 32'hc6e00bf3; assign K_array[29] = 32'hd5a79147;
    assign K_array[30] = 32'h06ca6351; assign K_array[31] = 32'h14292967;
    assign K_array[32] = 32'h27b70a85; assign K_array[33] = 32'h2e1b2138;
    assign K_array[34] = 32'h4d2c6dfc; assign K_array[35] = 32'h53380d13;
    assign K_array[36] = 32'h650a7354; assign K_array[37] = 32'h766a0abb;
    assign K_array[38] = 32'h81c2c92e; assign K_array[39] = 32'h92722c85;
    assign K_array[40] = 32'ha2bfe8a1; assign K_array[41] = 32'ha81a664b;
    assign K_array[42] = 32'hc24b8b70; assign K_array[43] = 32'hc76c51a3;
    assign K_array[44] = 32'hd192e819; assign K_array[45] = 32'hd6990624;
    assign K_array[46] = 32'hf40e3585; assign K_array[47] = 32'h106aa070;
    assign K_array[48] = 32'h19a4c116; assign K_array[49] = 32'h1e376c08;
    assign K_array[50] = 32'h2748774c; assign K_array[51] = 32'h34b0bcb5;
    assign K_array[52] = 32'h391c0cb3; assign K_array[53] = 32'h4ed8aa4a;
    assign K_array[54] = 32'h5b9cca4f; assign K_array[55] = 32'h682e6ff3;
    assign K_array[56] = 32'h748f82ee; assign K_array[57] = 32'h78a5636f;
    assign K_array[58] = 32'h84c87814; assign K_array[59] = 32'h8cc70208;
    assign K_array[60] = 32'h90befffa; assign K_array[61] = 32'ha4506ceb;
    assign K_array[62] = 32'hbef9a3f7; assign K_array[63] = 32'hc67178f2;
    
    //64 stage
    genvar i;
    generate
        for (i = 0; i < 64; i = i + 1) begin : pipe_stages
            sha256_pipeline_stage stage_inst (
                .clk(clk), .reset_n(reset_n), .valid_in(val_net[i]),
                
                .a_in(a_net[i]), .b_in(b_net[i]), .c_in(c_net[i]), .d_in(d_net[i]),
                .e_in(e_net[i]), .f_in(f_net[i]), .g_in(g_net[i]), .h_in(h_net[i]),
                
                .H0_in(H0_net[i]), .H1_in(H1_net[i]), .H2_in(H2_net[i]), .H3_in(H3_net[i]),
                .H4_in(H4_net[i]), .H5_in(H5_net[i]), .H6_in(H6_net[i]), .H7_in(H7_net[i]),
                
                .W0(W_net[i][0]), .W1(W_net[i][1]), .W2(W_net[i][2]), .W3(W_net[i][3]),
                .W4(W_net[i][4]), .W5(W_net[i][5]), .W6(W_net[i][6]), .W7(W_net[i][7]),
                .W8(W_net[i][8]), .W9(W_net[i][9]), .W10(W_net[i][10]), .W11(W_net[i][11]),
                .W12(W_net[i][12]), .W13(W_net[i][13]), .W14(W_net[i][14]), .W15(W_net[i][15]),
                
                .K_i(K_array[i]),
                
                .valid_out(val_net[i+1]),
                .a_out(a_net[i+1]), .b_out(b_net[i+1]), .c_out(c_net[i+1]), .d_out(d_net[i+1]),
                .e_out(e_net[i+1]), .f_out(f_net[i+1]), .g_out(g_net[i+1]), .h_out(h_net[i+1]),
                
                .H0_out(H0_net[i+1]), .H1_out(H1_net[i+1]), .H2_out(H2_net[i+1]), .H3_out(H3_net[i+1]),
                .H4_out(H4_net[i+1]), .H5_out(H5_net[i+1]), .H6_out(H6_net[i+1]), .H7_out(H7_net[i+1]),
                
                .W0_o(W_net[i+1][0]), .W1_o(W_net[i+1][1]), .W2_o(W_net[i+1][2]), .W3_o(W_net[i+1][3]),
                .W4_o(W_net[i+1][4]), .W5_o(W_net[i+1][5]), .W6_o(W_net[i+1][6]), .W7_o(W_net[i+1][7]),
                .W8_o(W_net[i+1][8]), .W9_o(W_net[i+1][9]), .W10_o(W_net[i+1][10]), .W11_o(W_net[i+1][11]),
                .W12_o(W_net[i+1][12]), .W13_o(W_net[i+1][13]), .W14_o(W_net[i+1][14]), .W15_o(W_net[i+1][15])
            );
        end
    endgenerate
    wire [31:0] final_H0 = a_net[64] + H0_net[64];
    wire [31:0] final_H1 = b_net[64] + H1_net[64];
    wire [31:0] final_H2 = c_net[64] + H2_net[64];
    wire [31:0] final_H3 = d_net[64] + H3_net[64];
    wire [31:0] final_H4 = e_net[64] + H4_net[64];
    wire [31:0] final_H5 = f_net[64] + H5_net[64];
    wire [31:0] final_H6 = g_net[64] + H6_net[64];
    wire [31:0] final_H7 = h_net[64] + H7_net[64];
    
    assign valid_out = val_net[64];
    assign digest_out = {final_H0,final_H1,final_H2,final_H3,final_H4,final_H5,final_H6,final_H7};
endmodule
