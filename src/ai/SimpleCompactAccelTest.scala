// SimpleCompactAccelTest.scala - Unit test for SimpleCompactAccel
package riscv.ai

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class SimpleCompactAccelTest extends AnyFlatSpec with ChiselScalatestTester {
  
  "SimpleCompactAccel" should "compute 2x2 identity matrix multiplication" in {
    test(new SimpleCompactAccel()) { dut =>
      // Set matrix size to 2x2
      dut.io.reg.valid.poke(true.B)
      dut.io.reg.wen.poke(true.B)
      dut.io.reg.addr.poke(0x01C.U)
      dut.io.reg.wdata.poke(2.U)
      dut.clock.step()
      dut.io.reg.valid.poke(false.B)
      dut.clock.step()
      
      // Write matrix A: [1 2]
      //                 [3 4]
      val matrixA = Seq(1, 2, 3, 4)
      for (i <- 0 until 2) {
        for (j <- 0 until 2) {
          val addr = 0x100 + (i * 8 + j) * 4
          dut.io.reg.valid.poke(true.B)
          dut.io.reg.wen.poke(true.B)
          dut.io.reg.addr.poke(addr.U)
          dut.io.reg.wdata.poke(matrixA(i * 2 + j).U)
          dut.clock.step()
          dut.io.reg.valid.poke(false.B)
          dut.clock.step()
        }
      }
      
      // Write matrix B (identity): [1 0]
      //                            [0 1]
      val matrixB = Seq(1, 0, 0, 1)
      for (i <- 0 until 2) {
        for (j <- 0 until 2) {
          val addr = 0x300 + (i * 8 + j) * 4
          dut.io.reg.valid.poke(true.B)
          dut.io.reg.wen.poke(true.B)
          dut.io.reg.addr.poke(addr.U)
          dut.io.reg.wdata.poke(matrixB(i * 2 + j).U)
          dut.clock.step()
          dut.io.reg.valid.poke(false.B)
          dut.clock.step()
        }
      }
      
      // Start computation
      dut.io.reg.valid.poke(true.B)
      dut.io.reg.wen.poke(true.B)
      dut.io.reg.addr.poke(0x000.U)
      dut.io.reg.wdata.poke(1.U)
      dut.clock.step()
      dut.io.reg.valid.poke(false.B)
      dut.clock.step()
      
      // Wait for completion (max 100 cycles)
      var cycles = 0
      var done = false
      while (cycles < 100 && !done) {
        dut.io.reg.valid.poke(true.B)
        dut.io.reg.ren.poke(true.B)
        dut.io.reg.addr.poke(0x004.U)
        dut.clock.step()
        val status = dut.io.reg.rdata.peek().litValue
        if (status == 2) {
          done = true
        }
        dut.io.reg.valid.poke(false.B)
        dut.clock.step()
        cycles += 1
      }
      
      assert(done, "Computation did not complete in time")
      
      // Read and verify results (should be same as A)
      val expected = Seq(1, 2, 3, 4)
      for (i <- 0 until 2) {
        for (j <- 0 until 2) {
          val addr = 0x500 + (i * 8 + j) * 4
          dut.io.reg.valid.poke(true.B)
          dut.io.reg.ren.poke(true.B)
          dut.io.reg.addr.poke(addr.U)
          dut.clock.step()
          val result = dut.io.reg.rdata.peek().litValue.toInt
          dut.io.reg.valid.poke(false.B)
          dut.clock.step()
          
          assert(result == expected(i * 2 + j), 
            s"Result[$i][$j] = $result, expected ${expected(i * 2 + j)}")
        }
      }
      
      println(s"✓ 2x2 identity matrix test passed in $cycles cycles")
    }
  }
  
  it should "compute 2x2 matrix multiplication" in {
    test(new SimpleCompactAccel()) { dut =>
      // Set matrix size to 2x2
      dut.io.reg.valid.poke(true.B)
      dut.io.reg.wen.poke(true.B)
      dut.io.reg.addr.poke(0x01C.U)
      dut.io.reg.wdata.poke(2.U)
      dut.clock.step()
      dut.io.reg.valid.poke(false.B)
      dut.clock.step()
      
      // Write matrix A: [1 2]
      //                 [3 4]
      val matrixA = Seq(1, 2, 3, 4)
      for (i <- 0 until 2) {
        for (j <- 0 until 2) {
          val addr = 0x100 + (i * 8 + j) * 4
          dut.io.reg.valid.poke(true.B)
          dut.io.reg.wen.poke(true.B)
          dut.io.reg.addr.poke(addr.U)
          dut.io.reg.wdata.poke(matrixA(i * 2 + j).U)
          dut.clock.step()
          dut.io.reg.valid.poke(false.B)
          dut.clock.step()
        }
      }
      
      // Write matrix B: [2 0]
      //                 [0 2]
      val matrixB = Seq(2, 0, 0, 2)
      for (i <- 0 until 2) {
        for (j <- 0 until 2) {
          val addr = 0x300 + (i * 8 + j) * 4
          dut.io.reg.valid.poke(true.B)
          dut.io.reg.wen.poke(true.B)
          dut.io.reg.addr.poke(addr.U)
          dut.io.reg.wdata.poke(matrixB(i * 2 + j).U)
          dut.clock.step()
          dut.io.reg.valid.poke(false.B)
          dut.clock.step()
        }
      }
      
      // Start computation
      dut.io.reg.valid.poke(true.B)
      dut.io.reg.wen.poke(true.B)
      dut.io.reg.addr.poke(0x000.U)
      dut.io.reg.wdata.poke(1.U)
      dut.clock.step()
      dut.io.reg.valid.poke(false.B)
      dut.clock.step()
      
      // Wait for completion
      var cycles = 0
      var done = false
      while (cycles < 100 && !done) {
        dut.io.reg.valid.poke(true.B)
        dut.io.reg.ren.poke(true.B)
        dut.io.reg.addr.poke(0x004.U)
        dut.clock.step()
        val status = dut.io.reg.rdata.peek().litValue
        if (status == 2) {
          done = true
        }
        dut.io.reg.valid.poke(false.B)
        dut.clock.step()
        cycles += 1
      }
      
      assert(done, "Computation did not complete in time")
      
      // Read and verify results: [2 4]
      //                          [6 8]
      val expected = Seq(2, 4, 6, 8)
      for (i <- 0 until 2) {
        for (j <- 0 until 2) {
          val addr = 0x500 + (i * 8 + j) * 4
          dut.io.reg.valid.poke(true.B)
          dut.io.reg.ren.poke(true.B)
          dut.io.reg.addr.poke(addr.U)
          dut.clock.step()
          val result = dut.io.reg.rdata.peek().litValue.toInt
          dut.io.reg.valid.poke(false.B)
          dut.clock.step()
          
          assert(result == expected(i * 2 + j), 
            s"Result[$i][$j] = $result, expected ${expected(i * 2 + j)}")
        }
      }
      
      println(s"✓ 2x2 matrix multiplication test passed in $cycles cycles")
    }
  }
}
