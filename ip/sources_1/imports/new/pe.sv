// ----------------------------------------------------------------
// pe_ai.sv
//
// This module defines a Processing Element (PE) for the MAC accelerator.
//
// Function:
// 1. Performs a signed multiplication of two input values, 'a' and 'b'.
// 2. The multiplication is performed combinationally, and the result 'c'
//    is registered at the output.
// 3. The operation is controlled by the 'enable' signal. When enabled,
//    the output register is updated with the new product. Otherwise, it
//    holds its previous value.
//
// Note: This design is a SystemVerilog adaptation of 'old/PE.sv'.
// ----------------------------------------------------------------

module pe #(
    parameter int DATA_BITWIDTH = 8
)(
    // clock, nreset
    input  wire clk,
    input  wire nrst,
    input  wire enable,

    // data inputs
    input  wire signed [DATA_BITWIDTH-1:0] a,
    input  wire signed [DATA_BITWIDTH-1:0] b,

    // data output
    output reg  signed [DATA_BITWIDTH*2-1:0] c
);

    // ----------------------------------------------------------------
    // Registered Multiplier
    // ----------------------------------------------------------------
    always_ff @(posedge clk or negedge nrst) begin
        if (!nrst)
            c <= '0;
        else if (enable)
            c <= a * b;
    end

endmodule
