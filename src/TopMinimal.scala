package ysyx

import chisel3._
import org.chipsalliance.cde.config.{Parameters, Config}
import freechips.rocketchip.system._
import freechips.rocketchip.diplomacy.LazyModule

// 精简版顶层 - 用于生成 <10K 门的设计
class ysyxSoCTopMinimal extends Module {
  implicit val config: Parameters = new Config(new Edge32BitConfig ++ new DefaultRV32Config)

  val io = IO(new Bundle { })
  val dut = LazyModule(new ysyxSoCMinimalTop)
  val mdut = Module(dut.module)
  mdut.dontTouchPorts()
  mdut.externalPins := DontCare
}

object ElaborateMinimal extends App {
  val firtoolOptions = Array(
    "--disable-annotation-unknown",
    "--disable-all-randomization",
    "--strip-debug-info",
    "--lowering-options=disallowLocalVariables" // 减少生成的 Verilog 复杂度
  )
  circt.stage.ChiselStage.emitSystemVerilogFile(
    new ysyxSoCTopMinimal, 
    args, 
    firtoolOptions
  )
}
