module processing_element (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               weight_load_en,
    input  logic signed [3:0]  act_in,         // INT4 Activation
    input  logic signed [15:0] psum_in,        // INT16 Partial Sum
    output logic signed [3:0]  act_out,
    output logic signed [15:0] psum_out
);
    logic signed [3:0] weight_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_reg <= 4'sd0;
            act_out    <= 4'sd0;
            psum_out   <= 16'sd0;
        end else begin
            if (weight_load_en) begin
                weight_reg <= act_in;  
                act_out    <= act_in;  
            end else begin
                act_out  <= act_in;    
                psum_out <= (act_in * weight_reg) + psum_in;
            end
        end
    end
endmodule
