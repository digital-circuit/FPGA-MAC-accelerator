# Block design
## rule

        {temp_IP: label}: add IP "temp_IP" labeled "label"
        (IP0, port0 → IP1, port0): Connect port0(IP0) to port0(IP1)
        wiring automation: click "Run Block Automation"

## add IP
        {ZYNQ7 Processing System: ZYNQ7}
        → wiring automation
        → {AXI Direct Memory Access: axi_dma_0}
        → {AXI Direct Memory Access: axi_dma_1}
        → {AXI Direct Memory Access: axi_dma_2}
        → {AXI Direct Memory Access: axi_dma_3}
        → wiring automation ※ processing_system7_0 ☐ ..... (1)
        → {mac_axis}
        → (axi_dma_0, M_AXIS_MM2S → mac_axis, FIFO_axis)
        → (axi_dma_1, M_AXIS_MM2S → mac_axis, BRAM_axis)
        → (axi_dma_2, M_AXIS_MM2S → mac_axis, param_axis)
        → (axi_dma_3, S_AXIS_MM2S → mac_axis, output_axis)
        → {AXI SmartConnect: AXI_ic} # Don't confuse with "AXI SmartConnect" that added at (1)
        → (axi_dma_0, M_AXI_MM2S → AXI_ic, S00_AXI)
        → (axi_dma_1, M_AXI_MM2S → AXI_ic, S01_AXI)
        → (axi_dma_2, M_AXI_MM2S → AXI_ic, S02_AXI)
        → (axi_dma_3, S_AXI_MM2S → AXI_ic, S03_AXI)
        → (ZYNQ7, S_AXI_HP0 → AXI_ic, M00_AXI)
        → {concat: concat}
        → {axi_dma_0, mm2s_introut → concat, In0}
        → {axi_dma_1, mm2s_introut → concat, In1}
        → {axi_dma_2, mm2s_introut → concat, In2}
        → {axi_dma_3, s2mm_introut → concat, In3}
        → wiring automation

## IP Configurator
-  ZYNQ7 Processing System

        → PS-PL Configuration 
            → HP Slave AXI interface 
                S AXI HP0 interface: ☑
        → MIO Configuration 
            → Memory interface 
                Ouad SPI Flash: ☐
            → I/O Peripherais 
                ENET 0: ☑
                USB 0: ☑
                SD 0: ☑
            → GPIO
                GPIO MIO: ☐
                USB Reset: ☐
                I2C Reset: ☐
        → Clock Configuration
            → PL Fabric Clocks
                FCLK_CLK0: ☑/IO PLL/50
        → Interrupts
            → Fabric Insterrupts: ☑
                → PL-PS Interrupt Prots
                    IRQ_F2P : ☑

- AXI Direct Memory Access: axi_dma_0
  
        Enable Scatter Gather Engine: ☐
        Enable Micro DMA: ☐
        Width of Buffer Length Length register: 26
        Address Width: 32
        → Enable Read Channel: ☑
                Number of Channels: 1
                Memory Map Data Width: 128
                Stream Data Width: 128
                Max Burst Size: 256
                Allow Unaligned Transfers: ☑
        → Enable Write Channel: ☐

- AXI Direct Memory Access: axi_dma_1
  
        Enable Scatter Gather Engine: ☐
        Enable Micro DMA: ☐
        Width of Buffer Length Length register: 26
        Address Width: 32
        → Enable Read Channel: ☑
                Number of Channels: 1
                Memory Map Data Width: 128
                Stream Data Width: 128
                Max Burst Size: 256
                Allow Unaligned Transfers: ☑
        → Enable Write Channel: ☐

- AXI Direct Memory Access: axi_dma_2
  
        Enable Scatter Gather Engine: ☐
        Enable Micro DMA: ☐
        Width of Buffer Length Length register: 26
        Address Width: 32
        → Enable Read Channel: ☑
                Number of Channels: 1
                Memory Map Data Width: 32
                Stream Data Width: 32
                Max Burst Size: 256
                Allow Unaligned Transfers: ☑
        → Enable Write Channel: ☐

- AXI Direct Memory Access: axi_dma_3
  
        Enable Scatter Gather Engine: ☐
        Enable Micro DMA: ☐
        Width of Buffer Length Length register: 26
        Address Width: 32
        → Enable Read Channel: ☐
        → Enable Write Channel: ☑
                Number of Channels: 1
                Memory Map Data Width: 32
                Stream Data Width: 32
                Max Burst Size: 256
                Allow Unaligned Transfers: ☑

- AXI SmartConnect: AXI_ic

        → Top Level Settings
            Number of Slave interface: 4
            Number of Master interface: 1

- concat: concat

        Numver of Ports: 4

