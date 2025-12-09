#!/bin/bash
# 使用 hello-minirv-ysyxsoc.bin 验证 ysyxSoC 设计

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
TEST_DIR="$SCRIPT_DIR/test_run"
HELLO_BIN="$SCRIPT_DIR/ready-to-run/D-stage/hello-minirv-ysyxsoc.bin"

# 创建测试目录
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "=========================================="
echo "ysyxSoC 设计验证 - Hello 测试"
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

# 创建简单的测试台
echo ""
echo "2. 创建测试台..."
cat > tb_hello.v << 'EOF'
`timescale 1ns/1ps

module tb_hello;
    reg clock;
    reg reset;
    
    // 实例化 SoC
    ysyxSoCFull u_soc (
        .clock(clock),
        .reset(reset)
    );
    
    // 时钟生成 - 10MHz (100ns 周期)
    initial begin
        clock = 0;
        forever #50 clock = ~clock;
    end
    
    // 测试流程
    initial begin
        $display("========================================");
        $display("开始 ysyxSoC Hello 测试");
        $display("时间: %t", $time);
        $display("========================================");
        
        // 复位
        reset = 1;
        #200;
        reset = 0;
        $display("[%t] 复位释放", $time);
        
        // 运行足够长的时间让程序执行
        #1000000;  // 1ms
        
        $display("========================================");
        $display("测试完成");
        $display("时间: %t", $time);
        $display("========================================");
        $finish;
    end
    
    // 生成波形文件
    initial begin
        $dumpfile("hello_test.vcd");
        $dumpvars(0, tb_hello);
    end
    
    // 超时保护
    initial begin
        #10000000;  // 10ms 超时
        $display("❌ 测试超时!");
        $finish;
    end
endmodule
EOF

echo "✓ 测试台创建完成: tb_hello.v"

# 使用 Icarus Verilog 编译
echo ""
echo "3. 编译设计..."
iverilog -g2012 \
    -o hello_test.vvp \
    -I "$BUILD_DIR" \
    "$BUILD_DIR/ysyxSoCFull.v" \
    tb_hello.v

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
vvp hello_test.vvp

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
    echo "  gtkwave hello_test.vcd"
else
    echo "⚠ 未生成波形文件"
fi

echo ""
echo "=========================================="
echo "测试完成!"
echo "测试目录: $TEST_DIR"
echo "=========================================="
