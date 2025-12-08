// AXI4ToSimpleReg.scala - Bridge between AXI4 and SimpleRegIO
// Converts AXI4-Lite transactions to SimpleRegIO interface

package ysyx

import chisel3._
import chisel3.util._
import riscv.ai.SimpleRegIO

class AXI4ToSimpleReg extends Module {
  val io = IO(new Bundle {
    // AXI4-Lite slave interface (simplified)
    val axi_awvalid = Input(Bool())
    val axi_awready = Output(Bool())
    val axi_awaddr = Input(UInt(32.W))
    
    val axi_wvalid = Input(Bool())
    val axi_wready = Output(Bool())
    val axi_wdata = Input(UInt(32.W))
    val axi_wstrb = Input(UInt(4.W))
    
    val axi_bvalid = Output(Bool())
    val axi_bready = Input(Bool())
    val axi_bresp = Output(UInt(2.W))
    
    val axi_arvalid = Input(Bool())
    val axi_arready = Output(Bool())
    val axi_araddr = Input(UInt(32.W))
    
    val axi_rvalid = Output(Bool())
    val axi_rready = Input(Bool())
    val axi_rdata = Output(UInt(32.W))
    val axi_rresp = Output(UInt(2.W))
    
    // SimpleRegIO master interface
    val reg = Flipped(new SimpleRegIO())
  })
  
  // State machine for write transactions
  val sWriteIdle :: sWriteAddr :: sWriteData :: sWriteResp :: Nil = Enum(4)
  val writeState = RegInit(sWriteIdle)
  
  // State machine for read transactions
  val sReadIdle :: sReadAddr :: sReadData :: Nil = Enum(3)
  val readState = RegInit(sReadIdle)
  
  // Registers to hold transaction data
  val writeAddr = RegInit(0.U(32.W))
  val writeData = RegInit(0.U(32.W))
  val readAddr = RegInit(0.U(32.W))
  
  // Default outputs
  io.axi_awready := false.B
  io.axi_wready := false.B
  io.axi_bvalid := false.B
  io.axi_bresp := 0.U  // OKAY
  io.axi_arready := false.B
  io.axi_rvalid := false.B
  io.axi_rdata := 0.U
  io.axi_rresp := 0.U  // OKAY
  
  io.reg.addr := 0.U
  io.reg.wdata := 0.U
  io.reg.wen := false.B
  io.reg.ren := false.B
  io.reg.valid := false.B
  
  // Write transaction state machine
  switch(writeState) {
    is(sWriteIdle) {
      io.axi_awready := true.B
      io.axi_wready := true.B
      when(io.axi_awvalid && io.axi_wvalid) {
        // Both address and data arrive together
        writeAddr := io.axi_awaddr
        writeData := io.axi_wdata
        writeState := sWriteData
      }.elsewhen(io.axi_awvalid) {
        // Address arrives first
        writeAddr := io.axi_awaddr
        writeState := sWriteAddr
      }.elsewhen(io.axi_wvalid) {
        // Data arrives first (unusual but valid)
        writeData := io.axi_wdata
        writeState := sWriteAddr
      }
    }
    is(sWriteAddr) {
      io.axi_awready := true.B
      io.axi_wready := true.B
      when(io.axi_awvalid) {
        writeAddr := io.axi_awaddr
        writeState := sWriteData
      }.elsewhen(io.axi_wvalid) {
        writeData := io.axi_wdata
        writeState := sWriteData
      }
    }
    is(sWriteData) {
      // Perform write to SimpleRegIO
      io.reg.addr := writeAddr
      io.reg.wdata := writeData
      io.reg.wen := true.B
      io.reg.valid := true.B
      when(io.reg.ready) {
        writeState := sWriteResp
      }
    }
    is(sWriteResp) {
      io.axi_bvalid := true.B
      when(io.axi_bready) {
        writeState := sWriteIdle
      }
    }
  }
  
  // Read transaction state machine
  switch(readState) {
    is(sReadIdle) {
      io.axi_arready := true.B
      when(io.axi_arvalid) {
        readAddr := io.axi_araddr
        readState := sReadAddr
      }
    }
    is(sReadAddr) {
      // Perform read from SimpleRegIO
      io.reg.addr := readAddr
      io.reg.ren := true.B
      io.reg.valid := true.B
      when(io.reg.ready) {
        readState := sReadData
      }
    }
    is(sReadData) {
      io.axi_rvalid := true.B
      io.axi_rdata := io.reg.rdata
      when(io.axi_rready) {
        readState := sReadIdle
      }
    }
  }
}
