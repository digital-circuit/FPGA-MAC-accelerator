module kernel_array #(
        parameter int BITWIDTH = 256,
        parameter int CAPACITY = 4096
    )(
        // clock, nreset
        input  wire                          clk,
        input  wire                          nrst,

        // read port
        input  wire [$clog2(CAPACITY)-1:0] rd_head_addr,
        input  wire [$clog2(CAPACITY)-1:0] rd_index,
        output wire [BITWIDTH-1:0]         rd_data,
        
        // write port
        input  wire                          wr_vld,
        output wire                          wr_rdy,
        input  wire                          wr_last,
        input  wire [$clog2(CAPACITY)-1:0]   wr_head_addr,
        input  wire [BITWIDTH-1:0]           wr_data,
        output reg                           wr_loading
    );
    // ----------------------------------------------------------------
    // parameter, wire, register
    // ----------------------------------------------------------------
    localparam BRAM_ADDR_BITWIDTH = $clog2(CAPACITY);

    wire wr_fire = wr_vld & wr_rdy;

    wire [BRAM_ADDR_BITWIDTH-1:0]   BRAM_rd_addr;
    wire [BITWIDTH-1:0]             BRAM_rd_data;

    wire                            BRAM_wr_enable;
    reg  [BRAM_ADDR_BITWIDTH-1:0]   BRAM_wr_index;
    wire [BRAM_ADDR_BITWIDTH-1:0]   BRAM_wr_addr;
    wire [BITWIDTH-1:0]             BRAM_wr_data;
    
    // ----------------------------------------------------------------
    // assignment
    // ----------------------------------------------------------------
    assign BRAM_rd_addr = rd_head_addr + rd_index;
    assign wr_rdy = 1'b1;
    assign rd_data = BRAM_rd_data;
    
    assign BRAM_wr_enable = wr_fire;
    assign BRAM_wr_addr = wr_head_addr + BRAM_wr_index;
    assign BRAM_wr_data = wr_data;

    // ----------------------------------------------------------------
    // write counter
    // ----------------------------------------------------------------
    always_ff @(posedge clk or negedge nrst) begin : BRAM_WRITE_COUNTER
        if (!nrst) begin
            BRAM_wr_index <= 0;
        end else if (wr_fire) begin
            BRAM_wr_index <= (wr_last == 1) ? 0 : BRAM_wr_index + 1 ;
        end 
    end

    // ----------------------------------------------------------------
    // BRAM
    // ----------------------------------------------------------------
    BRAM #(
        .BITWIDTH(BITWIDTH),
        .CAPACITY(CAPACITY)
    ) BRAM (
        // clock, nreset
        .clk(clk),
        .nrst(nrst),
        // read
        .rd_addr(BRAM_rd_addr),
        .rd_data(BRAM_rd_data),
        // write
        .wr_enable(BRAM_wr_enable),
        .wr_addr(BRAM_wr_addr),
        .wr_data(BRAM_wr_data)
    );

    // ----------------------------------------------------------------
    // enable
    // ----------------------------------------------------------------
    always_ff @(posedge clk or negedge nrst) begin : BRAM_ENABLE
        if (!nrst) begin
            wr_loading <= 1'b0;
        end else if (wr_last == 1) begin
            wr_loading <= 1'b0;
        end else if (wr_fire == 1) begin
            wr_loading <= 1'b1;
        end
    end
endmodule
