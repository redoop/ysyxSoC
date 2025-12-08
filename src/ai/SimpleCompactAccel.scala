// SimpleCompactAccel.scala - Simple Matrix Accelerator with Register Interface
// Extracted from EdgeAiSoCSimple.scala
//
// Features:
// - 8x8 matrix multiplication (configurable size)
// - Simple register interface (no AXI4-Lite)
// - Hardware matrix buffers (64 elements each)
// - Performance cycle counter

package riscv.ai

import chisel3._
import chisel3.util._

// Note: Requires SimpleRegIO from SimpleRegIO.scala

class SimpleCompactAccel extends Module {
  val io = IO(new Bundle {
    val reg = new SimpleRegIO()
    val irq = Output(Bool())
  })
  
  // 寄存器
  val ctrl = RegInit(0.U(32.W))
  val status = RegInit(0.U(32.W))
  val matrixSize = RegInit(8.U(32.W))
  val perfCycles = RegInit(0.U(32.W))
  
  // 矩阵缓冲区
  val matrixA = Mem(64, UInt(32.W))
  val matrixB = Mem(64, UInt(32.W))
  val matrixC = Mem(64, UInt(32.W))
  
  // 状态机
  val sIdle :: sCompute :: sDone :: Nil = Enum(3)
  val state = RegInit(sIdle)
  val computeCounter = RegInit(0.U(8.W))
  
  // 矩阵乘法计算索引
  val i = RegInit(0.U(4.W))  // 行索引
  val j = RegInit(0.U(4.W))  // 列索引
  val k = RegInit(0.U(4.W))  // 累加索引
  val accumulator = RegInit(0.U(32.W))
  
  // 默认输出
  io.reg.rdata := 0.U
  io.reg.ready := true.B
  io.irq := false.B
  
  // 计算状态机
  switch(state) {
    is(sIdle) {
      status := 0.U
      when(ctrl(0)) {
        state := sCompute
        computeCounter := 0.U
        perfCycles := 0.U
        i := 0.U
        j := 0.U
        k := 0.U
        accumulator := 0.U
      }
    }
    is(sCompute) {
      status := 1.U
      perfCycles := perfCycles + 1.U
      
      // 执行矩阵乘法: C[i][j] += A[i][k] * B[k][j]
      // 注意：矩阵存储为行优先，每行8个元素
      val aIdx = i * 8.U + k
      val bIdx = k * 8.U + j
      val aVal = matrixA(aIdx)
      val bVal = matrixB(bIdx)
      val product = aVal * bVal
      val newAccum = accumulator + product
      
      // 更新索引
      when(k < matrixSize - 1.U) {
        // 继续累加
        accumulator := newAccum
        k := k + 1.U
      }.otherwise {
        // k 循环完成，保存结果
        val cIdx = i * 8.U + j
        matrixC(cIdx) := newAccum  // 使用最新的累加值
        accumulator := 0.U
        k := 0.U
        
        // 移动到下一个元素
        when(j < matrixSize - 1.U) {
          j := j + 1.U
        }.otherwise {
          j := 0.U
          when(i < matrixSize - 1.U) {
            i := i + 1.U
          }.otherwise {
            // 计算完成
            state := sDone
          }
        }
      }
    }
    is(sDone) {
      status := 2.U
      io.irq := true.B
      ctrl := 0.U
      state := sIdle
    }
  }
  
  // 寄存器读写
  when(io.reg.valid) {
    val regAddr = io.reg.addr(11, 0)
    
    when(io.reg.wen) {
      switch(regAddr) {
        is(0x000.U) { ctrl := io.reg.wdata }
        is(0x01C.U) { matrixSize := io.reg.wdata }
      }
      
      // 矩阵 A 写入
      when(regAddr >= 0x100.U && regAddr < 0x200.U) {
        val idx = (regAddr - 0x100.U) >> 2
        matrixA(idx) := io.reg.wdata
      }
      
      // 矩阵 B 写入
      when(regAddr >= 0x300.U && regAddr < 0x400.U) {
        val idx = (regAddr - 0x300.U) >> 2
        matrixB(idx) := io.reg.wdata
      }
    }
    
    when(io.reg.ren) {
      switch(regAddr) {
        is(0x000.U) { io.reg.rdata := ctrl }
        is(0x004.U) { io.reg.rdata := status }
        is(0x01C.U) { io.reg.rdata := matrixSize }
        is(0x028.U) { io.reg.rdata := perfCycles }
      }
      
      // 矩阵 C 读取
      when(regAddr >= 0x500.U && regAddr < 0x600.U) {
        val idx = (regAddr - 0x500.U) >> 2
        io.reg.rdata := matrixC(idx)
      }
    }
  }
}
