package ysyx

import chisel3._
import chisel3.util._

import freechips.rocketchip.diplomacy._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.subsystem._
import freechips.rocketchip.util._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.amba.apb._

// 精简版 SoC - 仅保留 AI 加速器和基本功能
// 目标: <10,000 门,适配 iEDA
class ysyxSoCMinimal(implicit p: Parameters) extends LazyModule {
  // 简化的总线 - 只有一个 crossbar
  val xbar = AXI4Xbar()
  val apbxbar = LazyModule(new APBFanout).node
  
  // 使用新的 CPU 包装器 (适配 ysyx 接口)
  val cpu = LazyModule(new CPUMinimal(idBits = 4))
  
  // 只保留必需的外设
  val luart = LazyModule(new APBUart16550(AddressSet.misaligned(0x10000000, 0x1000)))
  
  // AI 加速器 (核心功能)
  val lcompact = LazyModule(new APBCompactAccel(AddressSet.misaligned(0x10003000, 0x1000)))
  val lbitnet = LazyModule(new APBBitNetAccel(AddressSet.misaligned(0x10004000, 0x1000)))
  
  // 小容量 SRAM (减少面积)
  val sramNode = AXI4RAM(AddressSet.misaligned(0x80000000L, 0x10000).head, false, true, 4, None, Nil, false)
  
  // 连接外设到 APB 总线
  List(luart.node, lcompact.node, lbitnet.node).map(_ := apbxbar)
  
  // 连接 APB 和 SRAM 到 AXI crossbar
  List(apbxbar := APBDelayer() := AXI4ToAPB() := AXI4Buffer(), sramNode).map(_ := xbar)
  
  // 连接 CPU 到 crossbar
  xbar := AXI4UserYanker(Some(1)) := AXI4Fragmenter() := cpu.masterNode
  
  // 连接 CPU slave 接口 (未使用)
  cpu.slaveNode := DontCare

  override lazy val module = new Impl
  class Impl extends LazyModuleImp(this) with DontTouch {
    // 简化的复位逻辑
    cpu.module.interrupt := false.B
    
    // 只暴露必需的接口
    val uart = IO(chiselTypeOf(luart.module.uart))
    val compact_irq = IO(Output(Bool()))
    val bitnet_irq = IO(Output(Bool()))
    
    uart <> luart.module.uart
    compact_irq := lcompact.module.irq
    bitnet_irq := lbitnet.module.irq
  }
}

// 精简版顶层 (不包含 FPGA 部分)
class ysyxSoCMinimalTop(implicit p: Parameters) extends LazyModule {
  val soc = LazyModule(new ysyxSoCMinimal)
  ElaborationArtefacts.add("graphml", graphML)

  override lazy val module = new Impl
  class Impl extends LazyModuleImp(this) with DontTouch {
    val msoc = soc.module
    msoc.dontTouchPorts()
    
    // 暴露外部接口
    val externalPins = IO(new Bundle{
      val uart = chiselTypeOf(msoc.uart)
      val compact_irq = Output(Bool())
      val bitnet_irq = Output(Bool())
    })
    
    externalPins.uart <> msoc.uart
    externalPins.compact_irq := msoc.compact_irq
    externalPins.bitnet_irq := msoc.bitnet_irq
  }
}
