// SimpleRegIO.scala - Simple Register Interface
// Extracted from EdgeAiSoCSimple.scala
//
// A lightweight register interface to replace AXI4-Lite for simple peripherals

package riscv.ai

import chisel3._

class SimpleRegIO extends Bundle {
  val addr = Input(UInt(32.W))
  val wdata = Input(UInt(32.W))
  val rdata = Output(UInt(32.W))
  val wen = Input(Bool())
  val ren = Input(Bool())
  val valid = Input(Bool())
  val ready = Output(Bool())
}
