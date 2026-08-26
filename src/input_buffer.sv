module input_buffer (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        cs,
    input  logic [7:0]  data_in,  
    output logic [31:0] data_out, 
    output logic        ready
);
    logic [2:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 32'd0;
            counter  <= 3'd0;
            ready    <= 1'b0;
        end else if (cs) begin
            data_out <= {data_out[23:0], data_in};
            counter  <= counter + 1;
            ready    <= (counter == 2'd3);
        end else begin
            ready <= 1'b0;
        end
    end
endmodule
