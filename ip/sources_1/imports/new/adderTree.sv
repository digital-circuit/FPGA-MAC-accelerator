module adderTree #(
    parameter int DATA_BITWIDTH = 16,
    parameter int PARALLEL = 16
)(
    // clock, nreset
    input  wire clk,
    input  wire nrst,
    input  wire enable,

    // data input
    input  wire signed [DATA_BITWIDTH-1:0] ab[PARALLEL],

    // data output
    output reg  signed [DATA_BITWIDTH + $clog2(PARALLEL) - 1:0] sum
);

    // ----------------------------------------------------------------
    // Local Parameters and Variables
    // ----------------------------------------------------------------
    localparam int STAGES = $clog2(PARALLEL);
    localparam int SUM_BITWIDTH = DATA_BITWIDTH + STAGES;

    // Wire array to hold intermediate sums for each stage of the tree
    wire signed [SUM_BITWIDTH-1:0] stage_data [0:STAGES][0:PARALLEL-1];

    // ----------------------------------------------------------------
    // Stage 0 Assignment
    // ----------------------------------------------------------------
    // Assign inputs to the first stage of the tree.
    generate
        for (genvar i = 0; i < PARALLEL; i = i + 1) begin : STAGE_0_ASSIGN
            assign stage_data[0][i] = ab[i];
        end
    endgenerate

    // ----------------------------------------------------------------
    // Combinatorial Adder Stages
    // ----------------------------------------------------------------
    generate
        for (genvar s = 0; s < STAGES; s = s + 1) begin : STAGE_LOOP
            // Sum pairs of inputs from the previous stage
            for (genvar j = 0; j < (PARALLEL >> (s + 1)); j = j + 1) begin : PAIR_LOOP
                assign stage_data[s+1][j] = stage_data[s][2*j] + stage_data[s][2*j+1];
            end

            // If there's an odd number of elements, pass the last one through
            if ((PARALLEL >> s) % 2 == 1) begin : ODD_ELEMENT_PASS
                assign stage_data[s+1][(PARALLEL >> (s + 1))] = stage_data[s][(PARALLEL >> s) - 1];
            end
        end
    endgenerate

    // ----------------------------------------------------------------
    // Output Register
    // ----------------------------------------------------------------
    // Register the final result from the top of the adder tree.
    always_ff @(posedge clk or negedge nrst) begin
        if (!nrst)
            sum <= '0;
        else if (enable)
            sum <= stage_data[STAGES][0];
 
    end

endmodule
