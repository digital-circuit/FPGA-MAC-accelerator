module axis_mac #(
        // core
        parameter int PALALLEL_N = 16,
        parameter int BITWIDTH = 8,
        // BRAM
        parameter int BRAM_CAPACITY = 1024,
        // FIFO
        parameter int FIFO_CAPACITY = 2048
    )(
        // clock, nreset
        input  wire clock,
        input  wire reset,

        // param axis: parameter
        input  wire param_axis_tvalid,
        output wire param_axis_tready,
        input  wire param_axis_tlast,
        input  wire [4-1:0] param_axis_tkeep,
        input  wire [32-1:0] param_axis_tdata,

        // BRAM axis: kernel
        input  wire BRAM_axis_tvalid,
        output wire BRAM_axis_tready,
        input  wire BRAM_axis_tlast,
        input  wire [(PALALLEL_N*BITWIDTH)/8-1:0] BRAM_axis_tkeep,
        input  wire [PALALLEL_N*BITWIDTH-1:0] BRAM_axis_tdata,

        // FIFO axis: feature
        input  wire FIFO_axis_tvalid,
        output wire FIFO_axis_tready,
        input  wire FIFO_axis_tlast,
        input  wire [(PALALLEL_N*BITWIDTH)/8-1:0] FIFO_axis_tkeep,
        input  wire [PALALLEL_N*BITWIDTH-1:0] FIFO_axis_tdata,  
          
        // output axis: MAC output
        output wire output_axis_tvalid,
        input  wire output_axis_tready,
        output wire output_axis_tlast,
        output wire [32/8-1:0] output_axis_tkeep,
        output wire [32-1:0] output_axis_tdata
    );
    // ----------------------------------------------------------------
    // BRAM
    // ----------------------------------------------------------------
    localparam int BRAM_BITWIDTH = PALALLEL_N*BITWIDTH;
    
    // ----------------------------------------------------------------
    // FIFO
    // ----------------------------------------------------------------
    localparam int FIFO_BITWIDTH = PALALLEL_N*BITWIDTH;
    
    // ----------------------------------------------------------------
    // output
    // ----------------------------------------------------------------
    assign output_axis_tkeep = '1;
    
    // ----------------------------------------------------------------
    // top
    // ----------------------------------------------------------------
    top_mac #(
        // core
        .PALALLEL_N(PALALLEL_N),
        .BITWIDTH(BITWIDTH),
        // BRAM
        .BRAM_CAPACITY(BRAM_CAPACITY),
        .BRAM_BITWIDTH(BRAM_BITWIDTH),
        // FIFO
        .FIFO_CAPACITY(FIFO_CAPACITY),
        .FIFO_BITWIDTH(FIFO_BITWIDTH)
    ) top (
        // clock, nreset
        .clk(clock),
        .nrst(!reset),
        // parameter
        .param_vld(param_axis_tvalid),
        .param_rdy(param_axis_tready),
        .param_last(param_axis_tlast),
        .param_data(param_axis_tdata),
        // BRAM
        .BRAM_vld(BRAM_axis_tvalid),
        .BRAM_rdy(BRAM_axis_tready),
        .BRAM_last(BRAM_axis_tlast),
        .BRAM_data(BRAM_axis_tdata),
        // FIFO
        .FIFO_vld(FIFO_axis_tvalid),
        .FIFO_rdy(FIFO_axis_tready),
        .FIFO_last(FIFO_axis_tlast),
        .FIFO_data(FIFO_axis_tdata),
        // output
        .output_vld(output_axis_tvalid),
        .output_rdy(output_axis_tready),
        .output_last(output_axis_tlast),
        .output_data(output_axis_tdata)
    );
    
endmodule
