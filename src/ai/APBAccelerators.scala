// APBAccelerators.scala - APB wrappers for AI accelerators
// Integrates SimpleCompactAccel and SimpleBitNetAccel into ysyxSoC

package ysyx

import chisel3._
import chisel3.util._
import freechips.rocketchip.amba.apb._
import freechips.rocketchip.diplomacy._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.util._
import riscv.ai._

// ============================================================================
// APB CompactAccel - Standard Matrix Multiplication Accelerator
// ============================================================================

class APBCompactAccel(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
  val node = APBSlaveNode(Seq(APBSlavePortParameters(
    Seq(APBSlaveParameters(
      address       = address,
      executable    = false,
      supportsRead  = true,
      supportsWrite = true)),
    beatBytes  = 4)))

  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val (in, _) = node.in(0)
    
    // Instantiate the accelerator
    val accel = Module(new SimpleCompactAccel())
    
    // APB to SimpleRegIO bridge
    val sIdle :: sAccess :: Nil = Enum(2)
    val state = RegInit(sIdle)
    
    // Default outputs
    in.pready := false.B
    in.prdata := 0.U
    in.pslverr := false.B
    
    accel.io.reg.addr := in.paddr
    accel.io.reg.wdata := in.pwdata
    accel.io.reg.wen := false.B
    accel.io.reg.ren := false.B
    accel.io.reg.valid := false.B
    
    // APB state machine
    switch(state) {
      is(sIdle) {
        when(in.psel && in.penable) {
          state := sAccess
          accel.io.reg.valid := true.B
          accel.io.reg.wen := in.pwrite
          accel.io.reg.ren := !in.pwrite
        }
      }
      is(sAccess) {
        accel.io.reg.valid := true.B
        accel.io.reg.wen := in.pwrite
        accel.io.reg.ren := !in.pwrite
        
        when(accel.io.reg.ready) {
          in.pready := true.B
          in.prdata := accel.io.reg.rdata
          state := sIdle
        }
      }
    }
    
    // Interrupt output (optional, can be connected to interrupt controller)
    val irq = IO(Output(Bool()))
    irq := accel.io.irq
  }
}

// ============================================================================
// APB BitNetAccel - Multiplication-Free BitNet Accelerator
// ============================================================================

class APBBitNetAccel(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
  val node = APBSlaveNode(Seq(APBSlavePortParameters(
    Seq(APBSlaveParameters(
      address       = address,
      executable    = false,
      supportsRead  = true,
      supportsWrite = true)),
    beatBytes  = 4)))

  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val (in, _) = node.in(0)
    
    // Instantiate the accelerator
    val accel = Module(new SimpleBitNetAccel())
    
    // APB to SimpleRegIO bridge
    val sIdle :: sAccess :: Nil = Enum(2)
    val state = RegInit(sIdle)
    
    // Default outputs
    in.pready := false.B
    in.prdata := 0.U
    in.pslverr := false.B
    
    accel.io.reg.addr := in.paddr
    accel.io.reg.wdata := in.pwdata
    accel.io.reg.wen := false.B
    accel.io.reg.ren := false.B
    accel.io.reg.valid := false.B
    
    // APB state machine
    switch(state) {
      is(sIdle) {
        when(in.psel && in.penable) {
          state := sAccess
          accel.io.reg.valid := true.B
          accel.io.reg.wen := in.pwrite
          accel.io.reg.ren := !in.pwrite
        }
      }
      is(sAccess) {
        accel.io.reg.valid := true.B
        accel.io.reg.wen := in.pwrite
        accel.io.reg.ren := !in.pwrite
        
        when(accel.io.reg.ready) {
          in.pready := true.B
          in.prdata := accel.io.reg.rdata
          state := sIdle
        }
      }
    }
    
    // Interrupt output (optional, can be connected to interrupt controller)
    val irq = IO(Output(Bool()))
    irq := accel.io.irq
  }
}
