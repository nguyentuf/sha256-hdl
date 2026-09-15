`default_nettype none

module sha256_padding (
    input  wire          clk,
    input  wire          reset_n,

    // Giao tiep Host 
    input  wire [7:0]    in_data,
    input  wire          valid_input,
    input  wire          lastbyte,
    output wire          pad_ready,

    // Giao tiep Core
    output reg [511:0]   block_out,
    output reg           valid_to_core,
    output reg           is_last_block,
    input  wire          valid_from_core,

    // Tin hieu hoan tat
    output reg           pad_done
);

    localparam [2:0] S_IDLE           = 3'd0,
                     S_RECV           = 3'd1,
                     S_PAD_10000000   = 3'd2,
                     S_PAD_ZEROES     = 3'd3,
                     S_PAD_LEN        = 3'd4,
                     S_START_HASH     = 3'd5,
                     S_WAIT_HASH      = 3'd6;

    reg [2:0]  state, next_state_after_hash;
    reg [7:0]  buffer [0:63];       
    reg [5:0]  byte_idx;            
    reg [63:0] total_bits;          
    integer i;

    assign pad_ready = (state == S_IDLE || state == S_RECV);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state                 <= S_IDLE;
            next_state_after_hash <= S_IDLE;
            byte_idx              <= 6'd0;
            total_bits            <= 64'd0;
            valid_to_core         <= 1'b0;
            is_last_block         <= 1'b0;
            pad_done              <= 1'b0;
            block_out             <= 512'd0;
            for (i = 0; i < 64; i = i + 1) buffer[i] <= 8'd0;
        end else begin
            valid_to_core <= 1'b0; 
            pad_done      <= 1'b0;

            case (state)
                S_IDLE: begin
                    byte_idx      <= 6'd0;
                    total_bits    <= 64'd0;
                    is_last_block <= 1'b0;
                    if (valid_input) begin
                        buffer[0]  <= in_data;
                        total_bits <= 64'd8;
                        if (lastbyte) state <= S_PAD_10000000;
                        else          state <= S_RECV;
                        byte_idx   <= 6'd1;
                    end
                end

                S_RECV: begin
                    if (valid_input) begin
                        buffer[byte_idx] <= in_data;
                        total_bits       <= total_bits + 64'd8;

                        if (byte_idx == 6'd63) begin
                            state <= S_START_HASH;
                            if (lastbyte) next_state_after_hash <= S_PAD_10000000;
                            else          next_state_after_hash <= S_RECV;
                        end else begin
                            if (lastbyte) state <= S_PAD_10000000;
                            byte_idx <= byte_idx + 1'b1;
                        end
                    end
                end

                S_PAD_10000000: begin
                    buffer[byte_idx] <= 8'h80;
                    if (byte_idx == 6'd63) begin
                        state                 <= S_START_HASH;
                        next_state_after_hash <= S_PAD_ZEROES;
                    end else begin
                        state    <= S_PAD_ZEROES;
                        byte_idx <= byte_idx + 1'b1;
                    end
                end

                S_PAD_ZEROES: begin
                    if (byte_idx == 6'd56) begin
                        state <= S_PAD_LEN;
                    end else if (byte_idx == 6'd63) begin
                        buffer[byte_idx]      <= 8'h00;
                        state                 <= S_START_HASH;
                        next_state_after_hash <= S_PAD_ZEROES;
                    end else begin
                        buffer[byte_idx] <= 8'h00;
                        byte_idx         <= byte_idx + 1'b1;
                    end
                end

                S_PAD_LEN: begin
                    buffer[56] <= total_bits[63:56]; buffer[57] <= total_bits[55:48];
                    buffer[58] <= total_bits[47:40]; buffer[59] <= total_bits[39:32];
                    buffer[60] <= total_bits[31:24]; buffer[61] <= total_bits[23:16];
                    buffer[62] <= total_bits[15:8];  buffer[63] <= total_bits[7:0];
                    state         <= S_START_HASH;
                    is_last_block <= 1'b1; 
                end

                S_START_HASH: begin
                    block_out <= {buffer[0], buffer[1], buffer[2], buffer[3], buffer[4], buffer[5], buffer[6], buffer[7],
                                  buffer[8], buffer[9], buffer[10], buffer[11], buffer[12], buffer[13], buffer[14], buffer[15],
                                  buffer[16], buffer[17], buffer[18], buffer[19], buffer[20], buffer[21], buffer[22], buffer[23],
                                  buffer[24], buffer[25], buffer[26], buffer[27], buffer[28], buffer[29], buffer[30], buffer[31],
                                  buffer[32], buffer[33], buffer[34], buffer[35], buffer[36], buffer[37], buffer[38], buffer[39],
                                  buffer[40], buffer[41], buffer[42], buffer[43], buffer[44], buffer[45], buffer[46], buffer[47],
                                  buffer[48], buffer[49], buffer[50], buffer[51], buffer[52], buffer[53], buffer[54], buffer[55],
                                  buffer[56], buffer[57], buffer[58], buffer[59], buffer[60], buffer[61], buffer[62], buffer[63]};
                    
                    state         <= S_WAIT_HASH;
                    valid_to_core <= 1'b1;
                end

                S_WAIT_HASH: begin
                    if (valid_from_core) begin
                        if (is_last_block) begin
                            pad_done <= 1'b1;
                            state    <= S_IDLE;
                        end else begin
                            byte_idx <= 6'd0;
                            state    <= next_state_after_hash;
                            for (i = 0; i < 64; i = i + 1) buffer[i] <= 8'd0;
                        end
                    end
                end
            endcase
        end
    end
endmodule
