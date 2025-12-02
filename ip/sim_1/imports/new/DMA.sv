/*
ver 1.0.0
*/

module DMA_i #(
    parameter int    BITWIDTH  = 32,
    parameter int    ITERATION = 64,
    parameter string FILE_NAME = "input_data.txt"
) (
    // clock, nreset
    input wire clock,
    input wire reset,

    // triger
    input wire fire,

    // AXI-Stream
    output reg                      axis_tvalid,
    input  wire                     axis_tready,
    output reg [BITWIDTH-1:0]     axis_tdata,
    output reg                      axis_tlast
);

    // ----------------------------------------------------------------
    // define variables
    // ----------------------------------------------------------------
    bit [BITWIDTH-1:0] queue[$];
    integer transfer_count;
        
    // ----------------------------------------------------------------
    // initial 
    // ----------------------------------------------------------------
    initial begin
        bit [BITWIDTH-1:0] data;
        integer handle;
        
        handle = $fopen(FILE_NAME, "r");
        
        if (handle == 0) begin
            $fatal(1, "[DMA] %s: file error", FILE_NAME);
        end

        while ($fscanf(handle, "%b\n", data) == 1) begin
            queue.push_back(data);
        end
        
        $fclose(handle);
        $display("[DMA] %s: loaded %d. (%d set)", FILE_NAME, queue.size(), queue.size()/ITERATION);
    end

    // ----------------------------------------------------------------
    // streaming
    // ----------------------------------------------------------------
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            axis_tvalid      <= 0;
            axis_tlast       <= 0;
            axis_tdata       <= 0;
            transfer_count   <= 0; 
        end 
        else begin
            
            if (axis_tvalid && axis_tready) begin
                void'(queue.pop_front()); 
                axis_tvalid <= 0; 
                
                if (axis_tlast) begin
                    transfer_count <= 0;
                end else begin
                    transfer_count <= transfer_count + 1;
                end
            end

            if (!axis_tvalid && fire) begin
                
                if (queue.size() > 0) begin
                    axis_tvalid <= 1;
                    axis_tdata  <= queue[0];

                    if (transfer_count == ITERATION - 1) begin
                        axis_tlast <= 1;
                    end else begin
                        axis_tlast <= 0;
                    end
                end
            end
        end
    end

endmodule

module DMA_o #(
    parameter int    BITWIDTH  = 32,
    parameter string FILE_NAME = "output_data.txt"
) (
    // clock, nreset
    input wire clock,
    input wire reset,

    // AXI-Stream
    input  reg                      axis_tvalid,
    output wire                     axis_tready,
    input  reg [BITWIDTH-1:0]       axis_tdata,
    input  reg                      axis_tlast,
    
    // counter
    output int finish,
    output int count_axis,
    output int count_right,
    output int count_wrong    
    
);      
    // ----------------------------------------------------------------
    // initial 
    // ----------------------------------------------------------------
    integer handle;
    integer state;
    bit [BITWIDTH-1:0] data;
    assign axis_tready = '1;
    
    initial begin
        handle = $fopen(FILE_NAME, "r");
        finish = 0;
        count_axis = 0;
        count_right = 0;
        count_wrong = 0;
        
        if (handle == 0) begin
            $fatal(1, "[DMA_o] %s: file error", FILE_NAME);
        end
        
        state = $fscanf(handle, "%b\n", data);
        
    end
    
    always @(posedge clock) begin
        if (axis_tvalid == 1) begin
            if (state == 1) begin
                count_axis++;
                
                if (data == axis_tdata) begin
                    count_right++;
                    $display("[DMA_o] %s: %b => %b.", FILE_NAME, data, axis_tdata);
                end else begin
                    count_wrong++;
                    $display("[DMA_o] %s: %b != %b. !!!!!!!!", FILE_NAME, data, axis_tdata);
                end
            end else begin
                $display("[DMA_o] %s: Overflow, %b.", FILE_NAME, axis_tdata);
            end
            
            state = $fscanf(handle, "%b\n", data);
            if (state == -1) begin
                finish = 1;
            end
        end 
    end
    

endmodule