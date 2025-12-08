// SimpleMemoryMap.scala - Memory Map Configuration
// Extracted from EdgeAiSoCSimple.scala
//
// Defines the memory map for the EdgeAiSoC system

package riscv.ai

object SimpleMemoryMap {
  val RAM_BASE = 0x00000000L
  val RAM_SIZE = 0x10000000L
  val PSRAM_BASE = 0x04000000L  // PSRAM: 8 MB
  val PSRAM_SIZE = 0x00800000L
  val COMPACT_BASE = 0x10000000L
  val COMPACT_SIZE = 0x00001000L
  val BITNET_BASE = 0x10001000L
  val BITNET_SIZE = 0x00001000L
  val UART_BASE = 0x20000000L
  val UART_SIZE = 0x00010000L
  val LCD_BASE = 0x20010000L
  val LCD_SIZE = 0x00010000L
  val GPIO_BASE = 0x20020000L
  val FLASH_BASE = 0x30000000L
  val FLASH_SIZE = 0x01000000L  // 16 MB
  val GPIO_SIZE = 0x00010000L
}
