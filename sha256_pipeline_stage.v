`default_nettype none

module sha256_pipeline_stage (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        valid_in,
    
    input  wire [31:0] a_in, b_in, c_in, d_in, e_in, f_in, g_in, h_in,
    input  wire [31:0] H0_in, H1_in, H2_in, H3_in, H4_in, H5_in, H6_in, H7_in,
    input  wire [31:0] W0, W1, W2, W3, W4, W5, W6, W7, W8, W9, W10, W11, W12, W13, W14, W15,
    input  wire [31:0] K_i,
    output reg         valid_out,
    output reg  [31:0] a_out, b_out, c_out, d_out, e_out, f_out, g_out, h_out,
    output reg  [31:0] H0_out, H1_out, H2_out, H3_out, H4_out, H5_out, H6_out, H7_out,
    output reg  [31:0] W0_o, W1_o, W2_o, W3_o, W4_o, W5_o, W6_o, W7_o,
    output reg  [31:0] W8_o, W9_o, W10_o, W11_o, W12_o, W13_o, W14_o, W15_o
);

    wire [31:0] Ch  = (e_in & f_in) ^ (~e_in & g_in);
    wire [31:0] Maj = (a_in & b_in) ^ (a_in & c_in) ^ (b_in & c_in);
    
    wire [31:0] s0_comp = {a_in[1:0], a_in[31:2]} ^ {a_in[12:0], a_in[31:13]} ^ {a_in[21:0], a_in[31:22]};
    wire [31:0] s1_comp = {e_in[5:0], e_in[31:6]} ^ {e_in[10:0], e_in[31:11]} ^ {e_in[24:0], e_in[31:25]};

    wire [31:0] T1 = h_in + s1_comp + Ch + K_i + W0;
    wire [31:0] T2 = s0_comp + Maj;

    wire [31:0] smallsigma0 = {W1[6:0], W1[31:7]} ^ {W1[17:0], W1[31:18]} ^ (W1 >> 3);
    wire [31:0] smallsigma1 = {W14[16:0], W14[31:17]} ^ {W14[18:0], W14[31:19]} ^ (W14 >> 10);
    wire [31:0] W_next = W0 + smallsigma0 + W9 + smallsigma1;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            valid_out <= 1'b0;
            a_out <= 32'd0; b_out <= 32'd0; c_out <= 32'd0; d_out <= 32'd0;
            e_out <= 32'd0; f_out <= 32'd0; g_out <= 32'd0; h_out <= 32'd0;
            
            H0_out <= 32'd0; H1_out <= 32'd0; H2_out <= 32'd0; H3_out <= 32'd0;
            H4_out <= 32'd0; H5_out <= 32'd0; H6_out <= 32'd0; H7_out <= 32'd0;
            
            W0_o <= 32'd0;  W1_o <= 32'd0;  W2_o <= 32'd0;  W3_o <= 32'd0;
            W4_o <= 32'd0;  W5_o <= 32'd0;  W6_o <= 32'd0;  W7_o <= 32'd0;
            W8_o <= 32'd0;  W9_o <= 32'd0;  W10_o<= 32'd0;  W11_o<= 32'd0;
            W12_o<= 32'd0;  W13_o<= 32'd0;  W14_o<= 32'd0;  W15_o<= 32'd0;
        end else begin
            valid_out <= valid_in;
            if (valid_in) begin
                h_out <= g_in;
                g_out <= f_in;
                f_out <= e_in;
                e_out <= d_in + T1;
                d_out <= c_in;
                c_out <= b_in;
                b_out <= a_in;
                a_out <= T1 + T2;

                H0_out <= H0_in; H1_out <= H1_in; H2_out <= H2_in; H3_out <= H3_in;
                H4_out <= H4_in; H5_out <= H5_in; H6_out <= H6_in; H7_out <= H7_in;

                W0_o <= W1;  W1_o <= W2;  W2_o <= W3;  W3_o <= W4;
                W4_o <= W5;  W5_o <= W6;  W6_o <= W7;  W7_o <= W8;
                W8_o <= W9;  W9_o <= W10; W10_o <= W11; W11_o <= W12;
                W12_o<= W13; W13_o<= W14; W14_o <= W15; W15_o <= W_next;
            end
        end
    end
endmodule