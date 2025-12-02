module buffer#(
        parameter int ITERATION = 3,
        parameter int BITWIDTH = 32
    )(
        // clock, nreset
        input  wire                         clk, 
        input  wire                         nrst,

        // axis input port
        input  wire                         axis_tvaild,
        output wire                         axis_tready,
        input  wire                         axis_tlast,
        input  wire [BITWIDTH-1:0]          axis_tdata,

        // output port
        output reg [BITWIDTH-1:0]           buffer_array[0:ITERATION-1],

        // control
        input  wire                         ext_busy
    );
    // ----------------------------------------------------------------
    // local parameter
    // ----------------------------------------------------------------
    localparam int ADDR_BITWIDTH = $clog2(ITERATION);
    
    // ----------------------------------------------------------------
    // define wire & register
    // ----------------------------------------------------------------
    reg [ADDR_BITWIDTH-1:0] wr_addr;
    wire                    axis_fire = axis_tvaild & axis_tready;

    // ----------------------------------------------------------------
    // assignment
    // ----------------------------------------------------------------
    assign axis_tready = ~ext_busy;


    // ----------------------------------------------------------------
    // addressing
    // ----------------------------------------------------------------
    always_ff @(posedge clk or negedge nrst) begin : BUFFER_ADDRESSING
        if (!nrst) begin
            wr_addr <= '0;
        end else if (axis_fire == 1) begin
            wr_addr <= (axis_tlast == 1) ? '0 : wr_addr + 1;
        end else begin
            wr_addr <= wr_addr;
        end
    end

    // ----------------------------------------------------------------
    // write
    // ----------------------------------------------------------------
    integer i;

    always_ff @(posedge clk) begin : BUFFER_WRITE
        if (axis_fire == 1) begin
            buffer_array[wr_addr] <= axis_tdata;
        end
    end

endmodule
