module controller #(
        // BRAM
        parameter int BRAM_ADDR_BITWIDTH = 12,
        parameter int FIFO_ADDR_BITWIDTH = 12
    )(
        // clock,, nreset
        input  wire clk,
        input  wire nrst,

        // parameter
        input wire [32-1:0] iteration,

        // BRAM
        output wire [BRAM_ADDR_BITWIDTH-1:0] BRAM_rd_index,

        // FIFO    
        input  wire FIFO_rd_vld,
        output wire FIFO_rd_rdy,
        input  wire [FIFO_ADDR_BITWIDTH-1:0] FIFO_usage,

        // output
        output wire output_wr_vld,
        input  wire output_wr_rdy,

        // core
        output wire core_enable,
        output reg  core_clear
    );

    // ----------------------------------------------------------------
    // define variables
    // ----------------------------------------------------------------
    localparam int PIPLINE_LEVEL = 2;  

    localparam  STATE_BITWIDTH = 4;  
    localparam  IDLE = 4'b0001, 
                RUN  = 4'b0010,
                WAIT = 4'b0100,
                SAVE = 4'b1000;
                 
                
    // FIFO
    wire FIFO_fire = FIFO_rd_vld & FIFO_rd_rdy;
    reg  FIFO_fire_dly;
    
    // output
    wire output_fire = output_wr_vld & output_wr_rdy;

    // FSM
    reg [32-1:0] cnt;
    reg [$clog2(PIPLINE_LEVEL)-1:0] wait_cnt;  
    (* fsm_encoding = "one-hot" *) reg [STATE_BITWIDTH-1:0] cstate;

    // ----------------------------------------------------------------
    // handshake
    // ----------------------------------------------------------------
    assign FIFO_rd_rdy = (cstate == RUN);
    assign output_wr_vld = (cstate == SAVE);

    // ----------------------------------------------------------------
    // BRAM
    // ----------------------------------------------------------------
    assign BRAM_rd_index = cnt;
    
    // ----------------------------------------------------------------
    // FIFO
    // ----------------------------------------------------------------
    always_ff @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            FIFO_fire_dly <= 0;
        end else begin
            FIFO_fire_dly <= FIFO_fire;
        end
    end

    // ----------------------------------------------------------------
    // FSM
    // ----------------------------------------------------------------
    assign core_enable = (cstate == RUN & FIFO_fire_dly);
    
    always_ff @(posedge clk or negedge nrst) begin : CORE_CLEAR
        if (!nrst) begin
            core_clear <= 1;
        end else if (cstate != IDLE) begin
            if (output_fire == 1) begin
                core_clear <= 1;
            end else begin
                core_clear <= 0;
            end 
        end
    end

    always_ff @(posedge clk or negedge nrst) begin : FSM_CNT
        if (!nrst)
            cnt <= 0;
        else if (cstate == RUN)
            cnt <= (FIFO_fire == 1) ? cnt + 1 : cnt;
        else 
            cnt <= 0;
    end

    always_ff @(posedge clk or negedge nrst) begin : FSM_CNT_WAIT
        if (!nrst)
            wait_cnt <= 0;
        else if (cstate == WAIT)
            wait_cnt <= wait_cnt + 1;
        else
            wait_cnt <= 0;
    end

    always_ff @(posedge clk or negedge nrst) begin : FSM_NSTATE
        if (!nrst) begin
            cstate <= IDLE;
        end else begin
            case(cstate) 
                IDLE: begin
                    if (FIFO_usage != 0)
                        cstate <= RUN;
                end
                RUN: begin
                    if (cnt == iteration) 
                        cstate <= WAIT;
                end
                WAIT: begin
                    if (wait_cnt == PIPLINE_LEVEL-1)
                        cstate <= SAVE;
                end
                SAVE: begin
                    if (output_fire == 1)
                        cstate <= IDLE;
                end
                default: 
                    cstate <= IDLE; 
            endcase
        end
    end

endmodule
