package ysyx

import chisel3._
import chisel3.util._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.diplomacy._
import org.chipsalliance.cde.config.Parameters

// CPU 包装器 - 适配 ysyx_00000001 的扁平化 AXI 接口
class CPUWrapperIO extends Bundle {
  val clock = Input(Clock())
  val reset = Input(Bool())
  val interrupt = Input(Bool())
  
  // AXI4 Master - 扁平化接口 (ysyx 格式)
  val master_awready = Input(Bool())
  val master_awvalid = Output(Bool())
  val master_awid = Output(UInt(4.W))
  val master_awaddr = Output(UInt(32.W))
  val master_awlen = Output(UInt(8.W))
  val master_awsize = Output(UInt(3.W))
  val master_awburst = Output(UInt(2.W))
  val master_awlock = Output(Bool())
  val master_awcache = Output(UInt(4.W))
  val master_awprot = Output(UInt(3.W))
  val master_awqos = Output(UInt(4.W))
  
  val master_wready = Input(Bool())
  val master_wvalid = Output(Bool())
  val master_wdata = Output(UInt(32.W))
  val master_wstrb = Output(UInt(4.W))
  val master_wlast = Output(Bool())
  
  val master_bready = Output(Bool())
  val master_bvalid = Input(Bool())
  val master_bid = Input(UInt(4.W))
  val master_bresp = Input(UInt(2.W))
  
  val master_arready = Input(Bool())
  val master_arvalid = Output(Bool())
  val master_arid = Output(UInt(4.W))
  val master_araddr = Output(UInt(32.W))
  val master_arlen = Output(UInt(8.W))
  val master_arsize = Output(UInt(3.W))
  val master_arburst = Output(UInt(2.W))
  val master_arlock = Output(Bool())
  val master_arcache = Output(UInt(4.W))
  val master_arprot = Output(UInt(3.W))
  val master_arqos = Output(UInt(4.W))
  
  val master_rready = Output(Bool())
  val master_rvalid = Input(Bool())
  val master_rid = Input(UInt(4.W))
  val master_rdata = Input(UInt(32.W))
  val master_rresp = Input(UInt(2.W))
  val master_rlast = Input(Bool())
  
  // AXI4 Slave - 扁平化接口 (未使用,但需要存在)
  val slave_awready = Output(Bool())
  val slave_awvalid = Input(Bool())
  val slave_awid = Input(UInt(4.W))
  val slave_awaddr = Input(UInt(32.W))
  val slave_awlen = Input(UInt(8.W))
  val slave_awsize = Input(UInt(3.W))
  val slave_awburst = Input(UInt(2.W))
  val slave_awlock = Input(Bool())
  val slave_awcache = Input(UInt(4.W))
  val slave_awprot = Input(UInt(3.W))
  val slave_awqos = Input(UInt(4.W))
  
  val slave_wready = Output(Bool())
  val slave_wvalid = Input(Bool())
  val slave_wdata = Input(UInt(32.W))
  val slave_wstrb = Input(UInt(4.W))
  val slave_wlast = Input(Bool())
  
  val slave_bready = Input(Bool())
  val slave_bvalid = Output(Bool())
  val slave_bid = Output(UInt(4.W))
  val slave_bresp = Output(UInt(2.W))
  
  val slave_arready = Output(Bool())
  val slave_arvalid = Input(Bool())
  val slave_arid = Input(UInt(4.W))
  val slave_araddr = Input(UInt(32.W))
  val slave_arlen = Input(UInt(8.W))
  val slave_arsize = Input(UInt(3.W))
  val slave_arburst = Input(UInt(2.W))
  val slave_arlock = Input(Bool())
  val slave_arcache = Input(UInt(4.W))
  val slave_arprot = Input(UInt(3.W))
  val slave_arqos = Input(UInt(4.W))
  
  val slave_rready = Input(Bool())
  val slave_rvalid = Output(Bool())
  val slave_rid = Output(UInt(4.W))
  val slave_rdata = Output(UInt(32.W))
  val slave_rresp = Output(UInt(2.W))
  val slave_rlast = Output(Bool())
}

// 使用 BlackBox 直接实例化 ysyx_00000001
class ysyx_00000001_BlackBox extends BlackBox {
  val io = IO(new CPUWrapperIO)
}

// CPU 模块 - 使用 BlackBox 替代原来的实现
class CPUMinimal(idBits: Int = 4)(implicit p: Parameters) extends LazyModule {
  val masterNode = AXI4MasterNode(Seq(AXI4MasterPortParameters(
    masters = Seq(AXI4MasterParameters(
      name = "cpu",
      id = IdRange(0, 1 << idBits)
    ))
  )))
  
  val slaveNode = AXI4SlaveNode(Seq(AXI4SlavePortParameters(
    slaves = Seq(AXI4SlaveParameters(
      address = Seq(AddressSet(0x80000000L, 0x0fffffffL)),
      supportsWrite = TransferSizes(1, 64),
      supportsRead = TransferSizes(1, 64)
    )),
    beatBytes = 4
  )))

  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val interrupt = IO(Input(Bool()))
    
    // 实例化 BlackBox
    val cpu = Module(new ysyx_00000001_BlackBox)
    
    // 连接时钟和复位
    cpu.io.clock := clock
    cpu.io.reset := reset
    cpu.io.interrupt := interrupt
    
    // 连接 AXI Master
    val (master, _) = masterNode.out.head
    cpu.io.master_awready := master.aw.ready
    master.aw.valid := cpu.io.master_awvalid
    master.aw.bits.id := cpu.io.master_awid
    master.aw.bits.addr := cpu.io.master_awaddr
    master.aw.bits.len := cpu.io.master_awlen
    master.aw.bits.size := cpu.io.master_awsize
    master.aw.bits.burst := cpu.io.master_awburst
    master.aw.bits.lock := cpu.io.master_awlock
    master.aw.bits.cache := cpu.io.master_awcache
    master.aw.bits.prot := cpu.io.master_awprot
    master.aw.bits.qos := cpu.io.master_awqos
    
    cpu.io.master_wready := master.w.ready
    master.w.valid := cpu.io.master_wvalid
    master.w.bits.data := cpu.io.master_wdata
    master.w.bits.strb := cpu.io.master_wstrb
    master.w.bits.last := cpu.io.master_wlast
    
    master.b.ready := cpu.io.master_bready
    cpu.io.master_bvalid := master.b.valid
    cpu.io.master_bid := master.b.bits.id
    cpu.io.master_bresp := master.b.bits.resp
    
    cpu.io.master_arready := master.ar.ready
    master.ar.valid := cpu.io.master_arvalid
    master.ar.bits.id := cpu.io.master_arid
    master.ar.bits.addr := cpu.io.master_araddr
    master.ar.bits.len := cpu.io.master_arlen
    master.ar.bits.size := cpu.io.master_arsize
    master.ar.bits.burst := cpu.io.master_arburst
    master.ar.bits.lock := cpu.io.master_arlock
    master.ar.bits.cache := cpu.io.master_arcache
    master.ar.bits.prot := cpu.io.master_arprot
    master.ar.bits.qos := cpu.io.master_arqos
    
    master.r.ready := cpu.io.master_rready
    cpu.io.master_rvalid := master.r.valid
    cpu.io.master_rid := master.r.bits.id
    cpu.io.master_rdata := master.r.bits.data
    cpu.io.master_rresp := master.r.bits.resp
    cpu.io.master_rlast := master.r.bits.last
    
    // Slave 接口 - 设置为默认值
    val (slave, _) = slaveNode.in.head
    cpu.io.slave_awvalid := false.B
    cpu.io.slave_awid := 0.U
    cpu.io.slave_awaddr := 0.U
    cpu.io.slave_awlen := 0.U
    cpu.io.slave_awsize := 0.U
    cpu.io.slave_awburst := 0.U
    cpu.io.slave_awlock := false.B
    cpu.io.slave_awcache := 0.U
    cpu.io.slave_awprot := 0.U
    cpu.io.slave_awqos := 0.U
    
    cpu.io.slave_wvalid := false.B
    cpu.io.slave_wdata := 0.U
    cpu.io.slave_wstrb := 0.U
    cpu.io.slave_wlast := false.B
    
    cpu.io.slave_bready := false.B
    
    cpu.io.slave_arvalid := false.B
    cpu.io.slave_arid := 0.U
    cpu.io.slave_araddr := 0.U
    cpu.io.slave_arlen := 0.U
    cpu.io.slave_arsize := 0.U
    cpu.io.slave_arburst := 0.U
    cpu.io.slave_arlock := false.B
    cpu.io.slave_arcache := 0.U
    cpu.io.slave_arprot := 0.U
    cpu.io.slave_arqos := 0.U
    
    cpu.io.slave_rready := false.B
    
    slave.aw.ready := false.B
    slave.w.ready := false.B
    slave.b.valid := false.B
    slave.b.bits := DontCare
    slave.ar.ready := false.B
    slave.r.valid := false.B
    slave.r.bits := DontCare
  }
}
