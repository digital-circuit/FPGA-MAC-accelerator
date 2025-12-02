module mac #(
        // core
        parameter int PALALLEL_N = 16,
        parameter int BITWIDTH = 8,
        // BRAM
        parameter int BRAM_ADDR_BITWIDTH = 12,
        // FIFO
        parameter int FIFO_ADDR_BITWIDTH = 12
    )(
        // clock, nreset
        input  wire clk,
        input  wire nrst,

        // parameter
        input wire [32-1:0] iteration,

        // BRAM
        output wire [BRAM_ADDR_BITWIDTH-1:0] BRAM_rd_index, 
        input  wire [PALALLEL_N*BITWIDTH-1:0] BRAM_rd_data,

        // FIFO 
        input  wire FIFO_rd_vld,
        output wire FIFO_rd_rdy,
        input  wire [PALALLEL_N*BITWIDTH-1:0] FIFO_rd_data,
        input  wire [FIFO_ADDR_BITWIDTH-1:0] FIFO_usage,   

        // output 
        output wire output_wr_vld,
        input  wire output_wr_rdy,
        output wire [32-1:0] output_wr_data
    );
    // ----------------------------------------------------------------
    // define variables
    // ----------------------------------------------------------------
    wire core_enable, core_clear;
    wire [32-1:0] core_output;

    // ----------------------------------------------------------------
    // controller
    // ----------------------------------------------------------------
    controller #(
        // BRAM
        .BRAM_ADDR_BITWIDTH(BRAM_ADDR_BITWIDTH),
        .FIFO_ADDR_BITWIDTH(FIFO_ADDR_BITWIDTH)
    ) controller (
        // clock, nreset
        .clk(clk),
        .nrst(nrst),
        // parameter
        .iteration(iteration),
        // BRAM
        .BRAM_rd_index(BRAM_rd_index),
        // FIFO
        .FIFO_rd_vld(FIFO_rd_vld),
        .FIFO_rd_rdy(FIFO_rd_rdy),
        .FIFO_usage(FIFO_usage),
        // output
        .output_wr_vld(output_wr_vld),
        .output_wr_rdy(output_wr_rdy),
        // core
        .core_enable(core_enable),
        .core_clear(core_clear)
    );
    // ----------------------------------------------------------------
    // core
    // ----------------------------------------------------------------
    assign output_wr_data = {{(32-BITWIDTH){1'b0}}, core_output};

    core #(
        // core
        .PALALLEL_N(PALALLEL_N),
        .BITWIDTH(BITWIDTH)
    ) core_inst (
        // clock, nreset
        .clk(clk),
        .nrst(nrst),
        // BRAM
        .BRAM_rd_data(BRAM_rd_data),
        // FIFO
        .FIFO_rd_data(FIFO_rd_data),
        // output
        .output_wr_data(core_output),
        // core
        .core_enable(core_enable),
        .core_clear(core_clear)
    );
endmodule