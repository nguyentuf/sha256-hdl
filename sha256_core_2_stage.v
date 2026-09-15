
module sha256_core_2stage (
    input  wire         clk,
    input  wire         reset_n,
    input  wire         valid_in,
    input  wire [511:0] block_in,
    input  wire [255:0] hash_init_in,
    
    output reg          done,
    output reg  [255:0] digest_out
);
    wire [31:0] K [0:63];
    assign K[0]=32'h428a2f98; assign K[1]=32'h71374491; assign K[2]=32'hb5c0fbcf; assign K[3]=32'he9b5dba5;
    assign K[4]=32'h3956c25b; assign K[5]=32'h59f111f1; assign K[6]=32'h923f82a4; assign K[7]=32'hab1c5ed5;
    assign K[8]=32'hd807aa98; assign K[9]=32'h12835b01; assign K[10]=32'h243185be; assign K[11]=32'h550c7dc3;
    assign K[12]=32'h72be5d74; assign K[13]=32'h80deb1fe; assign K[14]=32'h9bdc06a7; assign K[15]=32'hc19bf174;
    assign K[16]=32'he49b69c1; assign K[17]=32'hefbe4786; assign K[18]=32'h0fc19dc6; assign K[19]=32'h240ca1cc;
    assign K[20]=32'h2de92c6f; assign K[21]=32'h4a7484aa; assign K[22]=32'h5cb0a9dc; assign K[23]=32'h76f988da;
    assign K[24]=32'h983e5152; assign K[25]=32'ha831c66d; assign K[26]=32'hb00327c8; assign K[27]=32'hbf597fc7;
    assign K[28]=32'hc6e00bf3; assign K[29]=32'hd5a79147; assign K[30]=32'h06ca6351; assign K[31]=32'h14292967;
    assign K[32]=32'h27b70a85; assign K[33]=32'h2e1b2138; assign K[34]=32'h4d2c6dfc; assign K[35]=32'h53380d13;
    assign K[36]=32'h650a7354; assign K[37]=32'h766a0abb; assign K[38]=32'h81c2c92e; assign K[39]=32'h92722c85;
    assign K[40]=32'ha2bfe8a1; assign K[41]=32'ha81a664b; assign K[42]=32'hc24b8b70; assign K[43]=32'hc76c51a3;
    assign K[44]=32'hd192e819; assign K[45]=32'hd6990624; assign K[46]=32'hf40e3585; assign K[47]=32'h106aa070;
    assign K[48]=32'h19a4c116; assign K[49]=32'h1e376c08; assign K[50]=32'h2748774c; assign K[51]=32'h34b0bcb5;
    assign K[52]=32'h391c0cb3; assign K[53]=32'h4ed8aa4a; assign K[54]=32'h5b9cca4f; assign K[55]=32'h682e6ff3;
    assign K[56]=32'h748f82ee; assign K[57]=32'h78a5636f; assign K[58]=32'h84c87814; assign K[59]=32'h8cc70208;
    assign K[60]=32'h90befffa; assign K[61]=32'ha4506ceb; assign K[62]=32'hbef9a3f7; assign K[63]=32'hc67178f2;
    
    reg [31:0] a, b, c, d, e, f, g, h;
    reg [31:0] H_reg [0:7];
    reg [31:0] W [0:15];
    
    reg [5:0] round_cnt;
    reg stage;
    reg [1:0] state;
    
    localparam IDLE = 2'd0, PROCESS = 2'd1, UPDATE = 2'd2;
   // Pipeline register 
    reg [31:0] p_a, p_b, p_c, p_d, p_e, p_f, p_g, p_h;
    reg [31:0] p_Ch, p_Maj, p_s0, p_s1, p_h_K_W;
    reg [31:0] p_W_next;
    
    wire [31:0] sig0_w = {W[1][6:0], W[1][31:7]} ^ {W[1][17:0], W[1][31:18]} ^ (W[1] >> 3);
    wire [31:0] sig1_w = {W[14][16:0], W[14][31:17]} ^ {W[14][18:0], W[14][31:19]} ^ (W[14] >> 10);
    wire [31:0] W_next_comb = W[0] + sig0_w + W[9] + sig1_w;
    
    integer i;
    always @(posedge clk or negedge reset_n) begin
     if ( !reset_n) begin
     state <= IDLE; 
     done <= 1'b0; 
     stage <= 1'b0;
     digest_out <= 256'd0;
     end else begin
        done <= 0;
        case(state)
           IDLE : begin 
               if (valid_in) begin
                        a <= hash_init_in[255:224]; b <= hash_init_in[223:192];
                        c <= hash_init_in[191:160]; d <= hash_init_in[159:128];
                        e <= hash_init_in[127:96];  f <= hash_init_in[95:64];
                        g <= hash_init_in[63:32];   h <= hash_init_in[31:0];
                        
                        H_reg[0] <= hash_init_in[255:224]; H_reg[1] <= hash_init_in[223:192];
                        H_reg[2] <= hash_init_in[191:160]; H_reg[3] <= hash_init_in[159:128];
                        H_reg[4] <= hash_init_in[127:96];  H_reg[5] <= hash_init_in[95:64];
                        H_reg[6] <= hash_init_in[63:32];   H_reg[7] <= hash_init_in[31:0];
                        
                        W[0] <= block_in[511:480]; W[1] <= block_in[479:448]; W[2] <= block_in[447:416]; W[3] <= block_in[415:384];
                        W[4] <= block_in[383:352]; W[5] <= block_in[351:320]; W[6] <= block_in[319:288]; W[7] <= block_in[287:256];
                        W[8] <= block_in[255:224]; W[9] <= block_in[223:192]; W[10]<= block_in[191:160]; W[11]<= block_in[159:128];
                        W[12]<= block_in[127:96];  W[13]<= block_in[95:64];   W[14]<= block_in[63:32];   W[15]<= block_in[31:0];
     
                        round_cnt <= 0; stage <= 1'b0; state <= PROCESS;
                      end
                   end
            PROCESS: begin
            //piep stage 1
                if (stage == 1'b0) begin
                        p_Ch    <= (e & f) ^ (~e & g);
                        p_Maj   <= (a & b) ^ (a & c) ^ (b & c);
                        p_s0    <= {a[1:0], a[31:2]} ^ {a[12:0], a[31:13]} ^ {a[21:0], a[31:22]};
                        p_s1    <= {e[5:0], e[31:6]} ^ {e[10:0], e[31:11]} ^ {e[24:0], e[31:25]};
                        p_h_K_W <= h + K[round_cnt] + W[0]; // Tính s?n h + K + W
                        
                        p_W_next <= W_next_comb; // C?t tr? cho m?ch sinh W

                        p_a <= a; p_b <= b; p_c <= c; p_d <= d; 
                        p_e <= e; p_f <= f; p_g <= g; p_h <= h;
                        
                        stage <= 1'b1;
                end else begin
                        a <= (p_h_K_W + p_s1 + p_Ch) + (p_s0 + p_Maj); // T1 + T2
                        b <= p_a;
                        c <= p_b;
                        d <= p_c;
                        e <= p_d + (p_h_K_W + p_s1 + p_Ch);            // d + T1
                        f <= p_e;
                        g <= p_f;
                        h <= p_g;
                
                        for(i=0; i<15; i=i+1) W[i] <= W[i+1];
                        W[15] <= p_W_next;
                        
                        stage <= 1'b0;
                        
                        if(round_cnt == 63) state <= UPDATE;
                        else round_cnt <= round_cnt + 1;
                     end
                   end
                UPDATE : begin
                    done <= 1'b1;
                    digest_out <= {H_reg[0]+a, H_reg[1]+b, H_reg[2]+c, H_reg[3]+d, 
                                   H_reg[4]+e, H_reg[5]+f, H_reg[6]+g, H_reg[7]+h};
                    state <= IDLE;
                 end
              endcase
          end
        end
      endmodule
                        