module tt_um_npu_core (
    input  logic [7:0] ui_in,    
    output logic [7:0] uo_out,   
    input  logic [7:0] uio_in,   
    output logic [7:0] uio_out,  
    output logic [7:0] uio_oe,   
    input  logic       ena,      
    input  logic       clk,      
    input  logic       rst_n     
);
    assign uio_oe  = 8'b00000000;
    assign uio_out = 8'b00000000;

    wire weight_load_en = uio_in[0];
    wire buffer_cs      = uio_in[1];
    wire [2:0] col_sel  = uio_in[4:2]; 
    wire       byte_sel = uio_in[5]; // Only 1 bit needed to split a 16-bit answer!

    logic [31:0]  buffered_activations;
    logic         buffer_ready;
    logic [127:0] psum_in_flat;
    logic [127:0] psum_out_flat;

    assign psum_in_flat = 128'd0;

    input_buffer INPUT_STAGE (
        .clk        (clk),
        .rst_n      (rst_n),
        .cs         (buffer_cs),
        .data_in    (ui_in),
        .data_out   (buffered_activations),
        .ready      (buffer_ready)
    );

    systolic_array_8x8 CORE_ENGINE (
        .clk                  (clk),
        .rst_n                (rst_n),
        .weight_load_en       (weight_load_en),
        .act_in_left_flat     (buffered_activations),
        .psum_in_top_flat     (psum_in_flat),
        .psum_out_bottom_flat (psum_out_flat)
    );

    logic [15:0] selected_psum;
    assign selected_psum = (col_sel == 3'd0) ? psum_out_flat[15:0]   :
                           (col_sel == 3'd1) ? psum_out_flat[31:16]  :
                           (col_sel == 3'd2) ? psum_out_flat[47:32]  :
                           (col_sel == 3'd3) ? psum_out_flat[63:48]  :
                           (col_sel == 3'd4) ? psum_out_flat[79:64]  :
                           (col_sel == 3'd5) ? psum_out_flat[95:80]  :
                           (col_sel == 3'd6) ? psum_out_flat[111:96] :
                                               psum_out_flat[127:112];

    assign uo_out = (byte_sel == 1'b0) ? selected_psum[7:0] : selected_psum[15:8];

endmodule
