module FIFO #(
    parameter int BITWIDTH = 8,
    parameter int CAPACITY = 256
)(
    // Clock, Reset
    input  wire clk,
    input  wire nrst,

    // read port
    output reg  rd_vld,
    input  wire rd_rdy, 
    output reg  [BITWIDTH-1:0] rd_data,

    // write port
    input  wire wr_vld,
    output wire wr_rdy,
    input  wire [BITWIDTH-1:0] wr_data,

    // state
    (* KEEP = "TRUE" *) output wire [$clog2(CAPACITY)-1:0] usage
);

    // ------------------------------------------------------------------------
    // define variables
    // ------------------------------------------------------------------------
    localparam ADDR_BITWIDTH = $clog2(CAPACITY);

    (* ram_style = "distributed" *) reg [BITWIDTH-1:0] fifo[0:CAPACITY-1];
    
    wire rd_hk;
    reg  [ADDR_BITWIDTH-1:0] rd_addr;
    wire [ADDR_BITWIDTH-1:0] rd_addr_next;
    wire rd_vld_condition;
    
    wire                     wr_hk;
    reg  [ADDR_BITWIDTH-1:0] wr_addr;
    wire [ADDR_BITWIDTH-1:0] wr_addr_next;

    reg [ADDR_BITWIDTH:0] cnt;

    // ------------------------------------------------------------------------
    // handshake
    // ------------------------------------------------------------------------ 
    assign rd_hk = rd_vld_condition & rd_rdy;
    assign wr_hk = wr_vld & wr_rdy;

    assign rd_addr_next = (rd_addr == CAPACITY - 1) ? 0 : rd_addr + 1;
    assign wr_addr_next = (wr_addr == CAPACITY - 1) ? 0 : wr_addr + 1;
    assign rd_vld_condition = !(usage == 0);
    assign wr_rdy = cnt != CAPACITY;

    assign usage = cnt;
    
    always_ff @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            rd_vld <= '0;
        end else if (rd_rdy == 1) begin
            rd_vld <= rd_vld_condition;
        end else begin
            rd_vld <= 0;
        end
    end

    // ------------------------------------------------------------------------
    // counter
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge nrst) begin : CNT
        if (!nrst) begin
            cnt <= 0;
        end else if (rd_hk & !wr_hk) begin
            cnt <= cnt - 1;
        end else if (!rd_hk & wr_hk) begin
            cnt <= cnt + 1;
        end 
    end


    // ------------------------------------------------------------------------
    // Read & Write wire
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge nrst) begin : FIFO_WRITE_ADDR
        if (!nrst) begin
            wr_addr <= 0;
        end else if (wr_hk) begin
            wr_addr <= wr_addr_next;
        end
    end

    always_ff @(posedge clk) begin : FIFO_WRITE
        if (wr_hk) begin
            fifo[wr_addr] <= wr_data;
        end
    end

    always_ff @(posedge clk or negedge nrst) begin : FIFO_READ_ADDR
        if (!nrst) begin
            rd_addr <= 0;
        end else if (rd_hk) begin
            rd_addr <= rd_addr_next;
        end
    end
    
    always_ff @(posedge clk) begin : FIFO_READ
        if (!nrst) begin
            rd_data <= 0;
        end else begin
            rd_data <= fifo[rd_addr];
        end
    end
endmodule
