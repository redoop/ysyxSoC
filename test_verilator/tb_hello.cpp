#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VysyxSoCTop.h"
#include <iostream>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    
    VysyxSoCTop* top = new VysyxSoCTop;
    VerilatedVcdC* tfp = new VerilatedVcdC;
    
    top->trace(tfp, 99);
    tfp->open("hello_test.vcd");
    
    std::cout << "========================================" << std::endl;
    std::cout << "开始 ysyxSoC Hello 测试 (Verilator)" << std::endl;
    std::cout << "========================================" << std::endl;
    
    // 复位
    top->reset = 1;
    top->clock = 0;
    
    for (int i = 0; i < 10; i++) {
        top->clock = !top->clock;
        top->eval();
        tfp->dump(i);
    }
    
    top->reset = 0;
    std::cout << "复位释放" << std::endl;
    
    // 运行仿真
    int cycles = 0;
    int max_cycles = 100000;  // 最多运行 10 万个周期
    
    for (cycles = 0; cycles < max_cycles; cycles++) {
        top->clock = 0;
        top->eval();
        tfp->dump(2 * cycles + 10);
        
        top->clock = 1;
        top->eval();
        tfp->dump(2 * cycles + 11);
        
        if (cycles % 10000 == 0) {
            std::cout << "运行中... 周期: " << cycles << std::endl;
        }
    }
    
    std::cout << "========================================" << std::endl;
    std::cout << "测试完成" << std::endl;
    std::cout << "总周期数: " << cycles << std::endl;
    std::cout << "========================================" << std::endl;
    
    tfp->close();
    delete top;
    delete tfp;
    
    return 0;
}
