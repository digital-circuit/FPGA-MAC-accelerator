# Block design
 rule

        {temp_IP: label}: add IP "temp_IP" labeled "label"
        (IP0, port0 -> IP1, port0): Connect port0(IP0) to port0(IP1)
        wiring automation: click "Run Block Automation"

- add IP

        {ZYNQ7 Processing System}[1]
        → wiring automation
        → {AXI Direct Memory Access: DMA_i0}[2]
        → {AXI Direct Memory Access: DMA_i1}[3]
        → {AXI Direct Memory Access: DMA_i2}[4]
        → {AXI Direct Memory Access: DMA_o0}[5]

- ZYNQ7 Processing System[1]

        → PS-PL Configuration 
            → HP Slave AXI interface 
                S AXI HP0 interface: ☑
        → MIO Configuration 
            → Memory interface 
                Ouad SPI Flash: ☐
            → I/O Peripherais 
                ENET 0: ☐
                USB 0: ☐
                SD 0: ☐
            → GPIO
                GPIO MIO: ☐
                USB Reset: ☐
                I2C Reset: ☐
        → Clock Configuration
            → PL Fabric Clocks
                FCLK_CLK0: ☑/IO PLL/50
