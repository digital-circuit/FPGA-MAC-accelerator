module delay #(
        parameter int BITWIDTH = 32,
        parameter int N = 1
    )(
        input  wire                clk,
        input  wire                nrst,
        input  wire [BITWIDTH-1:0] i_data,
        output wire [BITWIDTH-1:0] o_data
    );
    
    reg [BITWIDTH-1:0] arr[0:N-1];
    
    assign o_data = arr[N-1];
    
    genvar i;
    generate
        for (i = 0; i < N; i++) begin : gen_delay_line
            always_ff @(posedge clk or negedge nrst) begin
                if (!nrst) begin
                    arr[i] <= '0; 
                end else begin
                    if (i == 0) begin
                        arr[i] <= i_data; 
                    end else begin
                        arr[i] <= arr[i-1]; 
                    end
                end
            end
        end
    endgenerate

endmodule