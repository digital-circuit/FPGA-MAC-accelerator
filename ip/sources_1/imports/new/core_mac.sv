// ----------------------------------------------------------------
// core_ai.sv
//
// This module represents the core of the MAC accelerator. It consists of
// an array of Processing Elements (PEs) and an AdderTree to perform
// parallel multiply-accumulate operations.
//
// Function:
// 1. Takes in a vector of kernel data (BRAM_rd_data) and a vector of
//    feature map data (FIFO_rd_data).
// 2. In each cycle where 'core_enable' is high, it multiplies corresponding
//    elements using the PE array.
// 3. The results from the PEs are summed up by the AdderTree.
// 4. The sum is accumulated over multiple cycles.
// 5. A 'clear' signal, generated from the rising edge of 'core_enable',
//    resets the accumulator for a new calculation sequence.
// 6. The final output is a requantized/sliced value from the accumulator.
//
// Instantiates:
// - pe_ai: Processing Element for multiplication.
// - adderTree_ai: Tree structure to sum PE outputs.
//
// Note: This design is based on the structure from 'old/core.sv' but
// adapted to the interface defined in 'new/mac.sv'.
// ----------------------------------------------------------------

module core #(
    parameter int PALALLEL_N = 16,
    parameter int BITWIDTH = 8
)(
    // clock, nreset
    input  wire clk,
    input  wire nrst,

    // core control
    input  wire core_enable,
    input  wire core_clear,

    // data inputs
    input  wire [PALALLEL_N*BITWIDTH-1:0] BRAM_rd_data, // from kernel buffer
    input  wire [PALALLEL_N*BITWIDTH-1:0] FIFO_rd_data, // from feature map FIFO

    // data output
    output wire [32-1:0] output_wr_data
);

    // ----------------------------------------------------------------
    // Local Parameters and Variables
    // ----------------------------------------------------------------
    localparam int PE_OUT_BITWIDTH = BITWIDTH * 2;
    localparam int SUM_BITWIDTH = PE_OUT_BITWIDTH + $clog2(PALALLEL_N);

    // Wires for PE outputs
    logic signed [PE_OUT_BITWIDTH-1:0] ab[PALALLEL_N];

    // Wire for AdderTree output
    logic signed [SUM_BITWIDTH-1:0] sum;

    // Accumulator register and next value wire
    reg   signed [32-1:0] acc_reg;
    wire  signed [32-1:0] acc_next;

    // Signal to clear accumulator on the first cycle of a new operation
    wire enable_MULT = core_enable;
    reg  enable_ADD;
    reg  enable_ACC;
    
    wire clear_ACC;
    
    delay #(.BITWIDTH(1), .N(3)) clear_delay (.clk(clk), .nrst(nrst), .i_data(core_clear), .o_data(clear_ACC));

    // ----------------------------------------------------------------
    // Clear Signal Generation
    // Detects the rising edge of core_enable to start a new accumulation.
    // ----------------------------------------------------------------
    always_ff @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            enable_ADD <= 1'b0;
            enable_ACC <= 1'b0;
        end else begin
            enable_ADD <= enable_MULT;
            enable_ACC <= enable_ADD;
        end
    end

    // ----------------------------------------------------------------
    // Processing Element (PE) Array
    // ----------------------------------------------------------------
    generate
        for (genvar i = 0; i < PALALLEL_N; i = i + 1) begin : PE_GEN
            pe #(
                .DATA_BITWIDTH(BITWIDTH)
            ) pe_inst (
                .clk(clk),
                .nrst(nrst),
                .enable(enable_MULT),
                .a(FIFO_rd_data[(i+1)*BITWIDTH-1 : i*BITWIDTH]),
                .b(BRAM_rd_data[(i+1)*BITWIDTH-1 : i*BITWIDTH]),
                .c(ab[i])
            );
        end
    endgenerate

    // ----------------------------------------------------------------
    // Adder Tree
    // ----------------------------------------------------------------
    adderTree #(
        .DATA_BITWIDTH(PE_OUT_BITWIDTH),
        .PARALLEL(PALALLEL_N)
    ) adderTree_inst (
        .clk(clk),
        .nrst(nrst),
        .enable(enable_ADD),
        .ab(ab),
        .sum(sum)
    );

    // ----------------------------------------------------------------
    // Accumulator
    // ----------------------------------------------------------------
    assign acc_next = sum + acc_reg;

    always_ff @(posedge clk or negedge nrst) begin
        if (!nrst)
            acc_reg <= '0;
        else if (clear_ACC)      // First cycle of a new calculation, load sum
            acc_reg <= '0;
        else if (enable_ACC) // Subsequent cycles, accumulate
            acc_reg <= acc_next;
        // If not enabled, the register holds its value.
    end

    // ----------------------------------------------------------------
    // Output Assignment
    // Requantize/slice the accumulated value similar to the old core.
    // This takes the sign bit and 7 bits from a specific position.
    // ----------------------------------------------------------------
    assign output_wr_data = acc_reg;

endmodule
