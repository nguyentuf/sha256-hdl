module sha256_top (
    input  wire          clk,
    input  wire          reset_n,
    input  wire [7:0]    in_data,       
    input  wire          valid_input,   
    input  wire          lastbyte,     
    output wire          pad_ready,     
    output wire          hash_done,    
    output wire [255:0]  digest        
);
    wire [511:0] internal_block;
    wire         internal_valid_to_core;
    wire         internal_is_last_block;
    wire         internal_valid_from_core;
    wire         pad_done;
    
    wire [255:0] core_digest_out;
    reg  [255:0] current_hash;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_hash <= {32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
                             32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19};
        end else begin
            if (pad_done) begin
                current_hash <= {32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
                                 32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19};
            end else if (internal_valid_from_core) begin
                current_hash <= core_digest_out;
            end
        end
    end
    
    sha256_padding inst1 (.clk(clk),.reset_n(reset_n),.in_data(in_data),.valid_input(valid_input),.lastbyte(lastbyte),.pad_ready(pad_ready),.valid_to_core(internal_valid_to_core),.is_last_block(internal_is_last_block),.valid_from_core(internal_valid_from_core),.pad_done(pad_done),.block_out(internal_block));
    sha256_core_fully_pipelined u_core (
        .clk          (clk),
        .reset_n      (reset_n),
        
        .valid_in     (internal_valid_to_core),
        .block_in     (internal_block),
        .hash_init_in (current_hash),
        
        .valid_out    (internal_valid_from_core),
        .digest_out   (core_digest_out)
    );
    assign hash_done = pad_done;
    assign digest = current_hash;
 endmodule