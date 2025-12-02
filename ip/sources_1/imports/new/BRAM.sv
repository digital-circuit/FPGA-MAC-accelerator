module BRAM #(
    parameter int BITWIDTH = 256,
    parameter int CAPACITY = 4096
)(
    // Clock, Reset
    input  logic                          clk,
    input  logic                          nrst,

    // Read Port
    input  logic [$clog2(CAPACITY)-1:0]   rd_addr,
    output logic [BITWIDTH-1:0]           rd_data,
    
    // Write Port
    input  logic                          wr_enable,
    input  logic [$clog2(CAPACITY)-1:0] wr_addr,
    input  logic [BITWIDTH-1:0]           wr_data
);
    // ------------------------------------------------------------------------
    // Memory Array
    // ------------------------------------------------------------------------
    (* ram_style = "block" *)logic [BITWIDTH-1:0] mem [CAPACITY];

    // ------------------------------------------------------------------------
    // Read & Write Logic
    // ------------------------------------------------------------------------
    always_ff @(posedge clk) begin : SRAM_WRITE
        if (wr_enable) begin
            mem[wr_addr] <= wr_data;
        end
    end

    always_ff @(posedge clk or negedge nrst) begin : SRAM_READ
        if (!nrst) begin
            rd_data <= '0;
        end else
            rd_data <= mem[rd_addr];
    end

endmodule
