module tb_axis_mac(

    );
    // ----------------------------------------------------------------
    // Parameters
    // ----------------------------------------------------------------
    // kernel, feature
    localparam int DATA_PALALLEL_N = 16;
    localparam int DATA_BITWIDTH   = 8;
    localparam int DATA_ITERATION  = 64;

    // parameter 
    localparam int PARAM_BITWIDTH  = 32;
    localparam int PARAM_ITERATION = 3;

    // ----------------------------------------------------------------
    // Signal
    // ----------------------------------------------------------------
    // clock, reset
    localparam int CLK = 20;

    logic clock; initial clock = 0; always #(CLK/2) clock = ~clock;
    logic reset;

    // ----------------------------------------------------------------
    // BRAM 
    // ----------------------------------------------------------------
    localparam int DMA_BRAM_ITERATION = DATA_ITERATION;
    localparam int DMA_BRAM_DATA_BITWIDTH = DATA_PALALLEL_N * DATA_BITWIDTH;    

    // AXI
    logic BRAM_axis_tready;
    logic BRAM_axis_tvalid;
    logic BRAM_axis_tlast;
    logic [DMA_BRAM_DATA_BITWIDTH-1:0] BRAM_axis_tdata;

    // logic
    logic BRAM_dma_fire;
    
    // DMA
    DMA_i #(
        .BITWIDTH(DMA_BRAM_DATA_BITWIDTH),   
        .ITERATION(DMA_BRAM_ITERATION),  
        .FILE_NAME("kernel.txt")
    ) BRAM_DMA (
        .clock, 
        .reset, 
        .fire(BRAM_dma_fire), 
        .axis_tvalid(BRAM_axis_tvalid), 
        .axis_tready(BRAM_axis_tready), 
        .axis_tdata(BRAM_axis_tdata), 
        .axis_tlast(BRAM_axis_tlast)
    );

    // ----------------------------------------------------------------
    // FIFO 
    // ----------------------------------------------------------------
    localparam int DMA_FIFO_ITERATION = DATA_ITERATION;
    localparam int DMA_FIFO_DATA_BITWIDTH = DATA_PALALLEL_N * DATA_BITWIDTH;    

    // AXI
    logic FIFO_axis_tready;
    logic FIFO_axis_tvalid;
    logic FIFO_axis_tlast;
    logic [DMA_FIFO_DATA_BITWIDTH-1:0] FIFO_axis_tdata;

    // logic
    logic FIFO_dma_fire;
    
    // DMA
    DMA_i #(
        .BITWIDTH(DMA_FIFO_DATA_BITWIDTH),   
        .ITERATION(DMA_FIFO_ITERATION),  
        .FILE_NAME("feature.txt")
    ) FIFO_DMA (
        .clock, 
        .reset, 
        .fire(FIFO_dma_fire), 
        .axis_tvalid(FIFO_axis_tvalid), 
        .axis_tready(FIFO_axis_tready), 
        .axis_tdata(FIFO_axis_tdata), 
        .axis_tlast(FIFO_axis_tlast)
    );

    // ----------------------------------------------------------------
    // PARAM 
    // ----------------------------------------------------------------
    localparam int DMA_PARAM_ITERATION = 3;
    localparam int DMA_PARAM_DATA_BITWIDTH = 32;    

    // AXI
    logic PARAM_axis_tready;
    logic PARAM_axis_tvalid;
    logic PARAM_axis_tlast;
    logic [DMA_PARAM_DATA_BITWIDTH-1:0] PARAM_axis_tdata;

    // logic
    logic PARAM_dma_fire;
    
    // DMA
    DMA_i #(
        .BITWIDTH(DMA_PARAM_DATA_BITWIDTH),   
        .ITERATION(DMA_PARAM_ITERATION),  
        .FILE_NAME("param.txt")
    ) PARAM_DMA (
        .clock, 
        .reset, 
        .fire(PARAM_dma_fire), 
        .axis_tvalid(PARAM_axis_tvalid), 
        .axis_tready(PARAM_axis_tready), 
        .axis_tdata(PARAM_axis_tdata), 
        .axis_tlast(PARAM_axis_tlast)
    );

    // ----------------------------------------------------------------
    // output 
    // ----------------------------------------------------------------
    localparam int DMA_output_DATA_BITWIDTH = 32;    

    // AXI
    logic output_axis_tready;
    logic output_axis_tvalid;
    logic output_axis_tlast;
    logic [DMA_output_DATA_BITWIDTH-1:0] output_axis_tdata;
    
    // siganl
    int output_count;
    int output_finish;
    int output_right;
    int output_wrong;
    
    // DMA
    DMA_o #(
        .BITWIDTH(DMA_output_DATA_BITWIDTH),   
        .FILE_NAME("output.txt")
    ) output_DMA (
        .clock, 
        .reset, 
        .axis_tvalid(output_axis_tvalid), 
        .axis_tready(output_axis_tready), 
        .axis_tdata(output_axis_tdata), 
        .axis_tlast(output_axis_tlast),
        .finish(output_finish),
        .count_axis(output_count),
        .count_right(output_right),
        .count_wrong(output_wrong)
    );

    // ----------------------------------------------------------------
    // Design under test
    // ----------------------------------------------------------------
    localparam int MAC_BRAM_CAPACITY = 1024;
    localparam int MAC_FIFO_CAPACITY = 128;
    
    axis_mac #(
        .PALALLEL_N(DATA_PALALLEL_N),
        .BITWIDTH(DATA_BITWIDTH),
        .BRAM_CAPACITY(MAC_BRAM_CAPACITY),
        .FIFO_CAPACITY(MAC_FIFO_CAPACITY)
    ) dut (
        .clock,
        .reset,
        .param_axis_tvalid(PARAM_axis_tvalid),
        .param_axis_tready(PARAM_axis_tready),
        .param_axis_tlast(PARAM_axis_tlast),
        .param_axis_tkeep('1),
        .param_axis_tdata(PARAM_axis_tdata),
        .BRAM_axis_tvalid(BRAM_axis_tvalid),
        .BRAM_axis_tready(BRAM_axis_tready),
        .BRAM_axis_tlast(BRAM_axis_tlast),
        .BRAM_axis_tkeep('1),
        .BRAM_axis_tdata(BRAM_axis_tdata),
        .FIFO_axis_tvalid(FIFO_axis_tvalid),
        .FIFO_axis_tready(FIFO_axis_tready),
        .FIFO_axis_tlast(FIFO_axis_tlast),
        .FIFO_axis_tkeep('1),
        .FIFO_axis_tdata(FIFO_axis_tdata),
        .output_axis_tvalid(output_axis_tvalid),
        .output_axis_tready(output_axis_tready),
        .output_axis_tlast(output_axis_tlast),
        .output_axis_tkeep(), 
        .output_axis_tdata(output_axis_tdata)
    );
    
    // ----------------------------------------------------------------
    // Tasks
    // ----------------------------------------------------------------
    // reset
    task reset_DMAs;
        reset = 1'b1;
        PARAM_dma_fire = 1'b0;
        BRAM_dma_fire  = 1'b0;
        FIFO_dma_fire  = 1'b0;
        
        # (CLK * 5);
        reset = 1'b0;
        
        # (CLK * 5);
        $display("DMA Reset.");
    endtask

    // DMA fire    
    task fire_param;
        PARAM_dma_fire = 1'b1;
        wait (PARAM_axis_tvalid & PARAM_axis_tready & PARAM_axis_tlast);
        PARAM_dma_fire = 1'b0;
    endtask
    
    task fire_BRAM;
        BRAM_dma_fire = 1'b1;
        wait (BRAM_axis_tvalid & BRAM_axis_tready & BRAM_axis_tlast);
        BRAM_dma_fire = 1'b0;
    endtask
    
    task fire_FIFO;
        FIFO_dma_fire = 1'b1;
        wait (FIFO_axis_tvalid & FIFO_axis_tready & FIFO_axis_tlast);
        FIFO_dma_fire = 1'b0;
    endtask


    // ----------------------------------------------------------------
    // Test Scenario
    // ----------------------------------------------------------------
    task schedule_filter;
        fire_param(); # (CLK * (DMA_PARAM_ITERATION+5));
        fire_BRAM(); # (CLK * (DATA_ITERATION+5));

        fire_param(); # (CLK * (DMA_PARAM_ITERATION+5));
        fire_BRAM(); # (CLK * (DATA_ITERATION+5));
    endtask
    
    task schedule_feature;
        # (CLK * 50);
        
        fire_FIFO(); # (CLK * 5);
        fire_FIFO(); # (CLK * 50);

        fire_param(); # (CLK * (DMA_PARAM_ITERATION+5));

        fire_FIFO(); # (CLK * 5);
        fire_FIFO(); # (CLK * 5); 
    endtask

    initial begin
        $display("Simulation Started");
        reset_DMAs();
        
        fork schedule_filter(); join_none
        fork schedule_feature(); join_none
        
        wait (output_finish == 1);
        # (CLK * 10); 
        $display("\nresult: %d / %d\n", output_right, output_count);
        $finish;
        
    end

endmodule
