// RTL file list for ysyxSoCFull synthesis
// All peripheral modules and main design

// CPU RTL
picorv32.v
ysyx_00000001.v

// AMBA
apb_delayer.v

// Peripherals
bitrev.v
flash_fixed.v
gpio_top_apb.v
ps2_top_apb.v

// PSRAM
EF_PSRAM_CTRL.v
EF_PSRAM_CTRL_wb.v
psram.v
psram_top_apb.v

// SDRAM
sdram.v
sdram_top_apb_fixed.v
sdram_axi_core.v

// SPI
spi_defines.v
spi_clgen.v
spi_shift.v
spi_top.v
spi_top_apb.v

// UART
uart_defines.v
raminfr.v
uart_sync_flops.v
uart_rfifo.v
uart_tfifo.v
uart_receiver.v
uart_transmitter.v
uart_regs.v
uart_top_apb.v

// VGA
vga_top_apb.v

// Main design (must be last)
ysyxSoCFull.v
