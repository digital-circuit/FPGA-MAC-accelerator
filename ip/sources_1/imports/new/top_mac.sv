module top_mac #(
        parameter int PALALLEL_N = 16,
        parameter int BITWIDTH = 8,
        parameter int BRAM_CAPACITY = 1024,
        parameter int BRAM_BITWIDTH = 128,
        parameter int FIFO_CAPACITY = 2048,
        parameter int FIFO_BITWIDTH = 128
    )(
        // clock, nreset
        input  wire clk,
        input  wire nrst,

        // parameter
        input  wire param_vld,
        output wire param_rdy,
        input  wire param_last,
        input  wire [32-1:0] param_data,

        // BRAM
        input  wire BRAM_vld,
        output wire BRAM_rdy,
        input  wire BRAM_last,
        input  wire [BRAM_BITWIDTH-1:0] BRAM_data,

        // FIFO
        input  wire FIFO_vld,
        output wire FIFO_rdy,
        input  wire FIFO_last,
        input  wire [FIFO_BITWIDTH-1:0] FIFO_data,

        // output
        output wire output_vld,
        input  wire output_rdy,
        output wire output_last,
        output wire [32-1:0] output_data
    );
    // ----------------------------------------------------------------
    // define variables
    // ----------------------------------------------------------------
    // parameter buffer
    localparam int PARAM_ITERATION = 3;
    localparam int PARAM_BITWIDTH = 32;
    
    wire [PARAM_BITWIDTH-1:0] BRAM_iteraiton;
    wire [PARAM_BITWIDTH-1:0] param_array[0:PARAM_ITERATION-1];

    // BRAM
    localparam BRAM_ADDR_BITWIDTH = $clog2(BRAM_CAPACITY);

    wire [BRAM_ADDR_BITWIDTH-1:0] BRAM_rd_head_addr;
    wire [BRAM_ADDR_BITWIDTH-1:0] BRAM_rd_index;
    wire [BRAM_BITWIDTH-1:0]      BRAM_rd_data;

    wire [BRAM_ADDR_BITWIDTH-1:0] BRAM_wr_head_addr;
    wire [BRAM_BITWIDTH-1:0] BRAM_wr_data;
    wire BRAM_wr_loading;

    // FIFO
    localparam FIFO_ADDR_BITWIDTH = $clog2(FIFO_CAPACITY);

    wire                     FIFO_rd_vld, FIFO_rd_rdy;
    wire [FIFO_BITWIDTH-1:0] FIFO_rd_data;
    wire                     FIFO_wr_vld, FIFO_wr_rdy;
    wire                     FIFO_wr_last;
    wire [FIFO_BITWIDTH-1:0] FIFO_wr_data;
    wire [FIFO_BITWIDTH-1:0] FIFO_rd_data_temp;

    wire [FIFO_ADDR_BITWIDTH-1:0] FIFO_usage;

    // output buffer
    wire                     output_rd_vld, output_rd_rdy;
    wire [32-1:0] output_rd_data;
    wire                     output_wr_vld, output_wr_rdy;
    wire [32-1:0] output_wr_data;

    // ----------------------------------------------------------------
    // parameter buffer
    // ----------------------------------------------------------------
    assign BRAM_iteraiton = param_array[0];
    assign BRAM_rd_head_addr = param_array[1][BRAM_ADDR_BITWIDTH-1:0];
    assign BRAM_wr_head_addr = param_array[2][BRAM_ADDR_BITWIDTH-1:0];
    
    buffer #(
        .ITERATION(PARAM_ITERATION),
        .BITWIDTH(PARAM_BITWIDTH)
    ) param_buffer (
        .clk(clk),
        .nrst(nrst),
        .axis_tvaild(param_vld),
        .axis_tready(param_rdy),
        .axis_tlast(param_last),
        .axis_tdata(param_data),
        .buffer_array(param_array),
        .ext_busy(BRAM_wr_loading)
    );

    // ----------------------------------------------------------------
    // BRAM
    // ----------------------------------------------------------------
    assign BRAM_wr_data = BRAM_data;

    kernel_array #(
        .BITWIDTH(BRAM_BITWIDTH),
        .CAPACITY(BRAM_CAPACITY)
    ) kernel_array (
        // clock, nreset
        .clk(clk),
        .nrst(nrst),
        // read
        .rd_head_addr(BRAM_rd_head_addr),
        .rd_index(BRAM_rd_index),
        .rd_data(BRAM_rd_data),
        // write
        .wr_vld(BRAM_vld),
        .wr_rdy(BRAM_rdy),
        .wr_last(BRAM_last),
        .wr_head_addr(BRAM_wr_head_addr),
        .wr_data(BRAM_wr_data),
        .wr_loading(BRAM_wr_loading)
    );

    // ----------------------------------------------------------------
    // FIFO
    // ----------------------------------------------------------------
    assign FIFO_wr_vld = FIFO_vld;
    assign FIFO_rdy = FIFO_wr_rdy;
    assign FIFO_wr_last = FIFO_last;
    assign FIFO_wr_data = FIFO_data;

    FIFO #(
        .BITWIDTH(FIFO_BITWIDTH),
        .CAPACITY(FIFO_CAPACITY)
    ) feature_buffer (
        // clock, nreset
        .clk(clk),
        .nrst(nrst),
        // read
        .rd_vld(FIFO_rd_vld),
        .rd_rdy(FIFO_rd_rdy),
        .rd_data(FIFO_rd_data_temp),
        // write
        .wr_vld(FIFO_wr_vld),
        .wr_rdy(FIFO_wr_rdy),
        .wr_data(FIFO_wr_data),
        // state
        .usage(FIFO_usage)
    );
    
    delay #(.BITWIDTH(FIFO_BITWIDTH), .N(1)) FIFO_delay (.clk(clk), .nrst(nrst), .i_data(FIFO_rd_data_temp), .o_data(FIFO_rd_data));

    // ----------------------------------------------------------------
    // output_buffer
    // ----------------------------------------------------------------
    assign output_vld = output_rd_vld;
    assign output_rd_rdy = output_rdy;
    assign output_data = output_rd_data;
    assign output_last = output_wr_vld & output_wr_rdy;

    FIFO #(
        .BITWIDTH(32),
        .CAPACITY(16)
    ) output_buffer (
        // clock, nreset
        .clk(clk),
        .nrst(nrst),
        // read
        .rd_vld(output_rd_vld),
        .rd_rdy(output_rd_rdy),
        .rd_data(output_rd_data),
        // write
        .wr_vld(output_wr_vld),
        .wr_rdy(output_wr_rdy),
        .wr_data(output_wr_data),
        .usage()
    );

    // ----------------------------------------------------------------
    // mac
    // ----------------------------------------------------------------
    mac #(
        // core
        .PALALLEL_N(PALALLEL_N),
        .BITWIDTH(BITWIDTH),
        // BRAM
        .BRAM_ADDR_BITWIDTH(BRAM_ADDR_BITWIDTH),
        // FIFO
        .FIFO_ADDR_BITWIDTH(FIFO_ADDR_BITWIDTH)
    ) mac (
        // clock, nreset
        .clk(clk),
        .nrst(nrst),
        // parameter
        .iteration(BRAM_iteraiton),
        // BRAM
        .BRAM_rd_index(BRAM_rd_index),
        .BRAM_rd_data(BRAM_rd_data),
        // FIFO
        .FIFO_rd_vld(FIFO_rd_vld), 
        .FIFO_rd_rdy(FIFO_rd_rdy),
        .FIFO_rd_data(FIFO_rd_data),
        .FIFO_usage(FIFO_usage),
        // output
        .output_wr_vld(output_wr_vld),
        .output_wr_rdy(output_wr_rdy),
        .output_wr_data(output_wr_data)
    );
endmodule
