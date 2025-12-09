#!/bin/bash
# 使用 Verilator 和 hello-minirv-ysyxsoc.bin 验证 ysyxSoC 设计

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
TEST_DIR="$SCRIPT_DIR/test_verilator"
HELLO_BIN="$SCRIPT_DIR/ready-to-run/D-stage/hello-minirv-ysyxsoc.bin"

# 创建测试目录
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "=========================================="
echo "ysyxSoC 设计验证 - Verilator + Hello"
echo "=========================================="
echo ""

# 检查必要文件
echo "1. 检查必要文件..."
if [ ! -f "$BUILD_DIR/ysyxSoCFull.v" ]; then
    echo "❌ 错误: 找不到 $BUILD_DIR/ysyxSoCFull.v"
    echo "请先运行: make verilog"
    exit 1
fi
echo "✓ 找到 Verilog 文件: $BUILD_DIR/ysyxSoCFull.v"

if [ ! -f "$HELLO_BIN" ]; then
    echo "❌ 错误: 找不到 $HELLO_BIN"
    exit 1
fi
echo "✓ 找到测试程序: $HELLO_BIN"

# 创建 C++ 测试台
echo ""
echo "2. 创建 C++ 测试台..."
cat > tb_hello.cpp << 'EOF'
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
EOF

echo "✓ C++ 测试台创建完成: tb_hello.cpp"

# 使用 Verilator 编译
echo ""
echo "3. 使用 Verilator 编译..."
echo "   (这可能需要几分钟...)"

verilator --cc \
    --exe \
    --build \
    --trace \
    -Wno-fatal \
    -Wno-WIDTH \
    -Wno-UNUSED \
    -Wno-UNDRIVEN \
    -Wno-BLKSEQ \
    --top-module ysyxSoCTop \
    "$BUILD_DIR/ysyxSoCFull.v" \
    tb_hello.cpp

if [ $? -eq 0 ]; then
    echo "✓ 编译成功"
else
    echo "❌ 编译失败"
    exit 1
fi

# 运行仿真
echo ""
echo "4. 运行仿真..."
echo "----------------------------------------"
./obj_dir/VysyxSoCTop

if [ $? -eq 0 ]; then
    echo "----------------------------------------"
    echo "✓ 仿真完成"
else
    echo "----------------------------------------"
    echo "❌ 仿真失败"
    exit 1
fi

# 检查波形文件
echo ""
echo "5. 检查结果..."
if [ -f "hello_test.vcd" ]; then
    VCD_SIZE=$(stat -f%z "hello_test.vcd" 2>/dev/null || stat -c%s "hello_test.vcd" 2>/dev/null)
    echo "✓ 生成波形文件: hello_test.vcd (大小: $VCD_SIZE 字节)"
    echo ""
    echo "查看波形文件:"
    echo "  cd $TEST_DIR"
    echo "  gtkwave hello_test.vcd"
else
    echo "⚠ 未生成波形文件"
fi

echo ""
echo "=========================================="
echo "测试完成!"
echo "测试目录: $TEST_DIR"
echo "=========================================="
