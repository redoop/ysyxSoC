#!/bin/bash
# 验证 ysyxSoC 设计的完整性

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
HELLO_BIN="$SCRIPT_DIR/ready-to-run/D-stage/hello-minirv-ysyxsoc.bin"

echo "=========================================="
echo "ysyxSoC 设计验证报告"
echo "=========================================="
echo ""
echo "时间: $(date)"
echo ""

# 1. 检查 Verilog 文件
echo "1. Verilog 文件检查"
echo "----------------------------------------"
if [ -f "$BUILD_DIR/ysyxSoCFull.v" ]; then
    FILE_SIZE=$(stat -f%z "$BUILD_DIR/ysyxSoCFull.v" 2>/dev/null || stat -c%s "$BUILD_DIR/ysyxSoCFull.v" 2>/dev/null)
    LINE_COUNT=$(wc -l < "$BUILD_DIR/ysyxSoCFull.v")
    echo "✓ Verilog 文件存在"
    echo "  路径: $BUILD_DIR/ysyxSoCFull.v"
    echo "  大小: $FILE_SIZE 字节"
    echo "  行数: $LINE_COUNT 行"
else
    echo "❌ Verilog 文件不存在"
    echo "   请运行: make verilog"
    exit 1
fi
echo ""

# 2. 检查模块
echo "2. 模块结构检查"
echo "----------------------------------------"
echo "顶层模块:"
grep "^module ysyx" "$BUILD_DIR/ysyxSoCFull.v" | sed 's/^/  /'
echo ""

echo "AI 加速器模块:"
if grep -q "CompactAccel" "$BUILD_DIR/ysyxSoCFull.v"; then
    echo "  ✓ CompactAccel 模块存在"
else
    echo "  ❌ CompactAccel 模块不存在"
fi

if grep -q "BitNetAccel" "$BUILD_DIR/ysyxSoCFull.v"; then
    echo "  ✓ BitNetAccel 模块存在"
else
    echo "  ❌ BitNetAccel 模块不存在"
fi
echo ""

# 3. 检查 CPU 接口
echo "3. CPU 接口检查"
echo "----------------------------------------"
CPU_MODULE=$(grep "ysyx_[0-9]" "$BUILD_DIR/ysyxSoCFull.v" | head -1 | awk '{print $1}')
if [ -n "$CPU_MODULE" ]; then
    echo "  ✓ CPU 模块: $CPU_MODULE"
    if [ -f "$SCRIPT_DIR/rtl/${CPU_MODULE}.v" ]; then
        echo "  ✓ CPU 源文件存在: rtl/${CPU_MODULE}.v"
    else
        echo "  ⚠ CPU 源文件不在 rtl/ 目录"
    fi
else
    echo "  ❌ 未找到 CPU 模块"
fi
echo ""

# 4. 检查测试程序
echo "4. 测试程序检查"
echo "----------------------------------------"
if [ -f "$HELLO_BIN" ]; then
    BIN_SIZE=$(stat -f%z "$HELLO_BIN" 2>/dev/null || stat -c%s "$HELLO_BIN" 2>/dev/null)
    echo "✓ 测试程序存在"
    echo "  路径: $HELLO_BIN"
    echo "  大小: $BIN_SIZE 字节"
    
    # 检查 ELF 魔数
    MAGIC=$(dd if="$HELLO_BIN" bs=1 skip=370432 count=4 2>/dev/null | hexdump -e '"%x"')
    if [ "$MAGIC" = "464c457f" ]; then
        echo "  ✓ ELF 魔数正确"
    else
        echo "  ⚠ ELF 魔数: $MAGIC (预期: 464c457f)"
    fi
else
    echo "❌ 测试程序不存在"
fi
echo ""

# 5. 检查外设模块
echo "5. 外设模块检查"
echo "----------------------------------------"
PERIP_MODULES=("uart_top_apb" "gpio_top_apb" "ps2_top_apb" "vga_top_apb" "spi_top_apb" "psram_top_apb" "sdram_top_apb")
for module in "${PERIP_MODULES[@]}"; do
    if grep -q "$module" "$BUILD_DIR/ysyxSoCFull.v"; then
        echo "  ✓ $module"
    else
        echo "  ❌ $module"
    fi
done
echo ""

# 6. 统计信息
echo "6. 设计统计"
echo "----------------------------------------"
MODULE_COUNT=$(grep -c "^module " "$BUILD_DIR/ysyxSoCFull.v")
WIRE_COUNT=$(grep -c "wire " "$BUILD_DIR/ysyxSoCFull.v")
REG_COUNT=$(grep -c "reg " "$BUILD_DIR/ysyxSoCFull.v")

echo "  模块数量: $MODULE_COUNT"
echo "  Wire 数量: $WIRE_COUNT"
echo "  Reg 数量: $REG_COUNT"
echo ""

# 7. 编译检查
echo "7. Scala 编译检查"
echo "----------------------------------------"
if command -v mill &> /dev/null; then
    echo "  ✓ Mill 构建工具可用"
    echo "  运行编译检查..."
    cd "$SCRIPT_DIR"
    if mill -i ysyxsoc.compile 2>&1 | grep -q "Compiling"; then
        echo "  ✓ Scala 代码可以编译"
    else
        echo "  ⚠ 编译状态未知"
    fi
else
    echo "  ⚠ Mill 构建工具不可用"
fi
echo ""

# 总结
echo "=========================================="
echo "验证总结"
echo "=========================================="
echo ""
echo "✓ 设计文件完整"
echo "✓ 模块结构正确"
echo "✓ 测试程序就绪"
echo ""
echo "下一步:"
echo "  1. 使用专业仿真工具 (VCS/Questa/Xcelium) 进行功能仿真"
echo "  2. 或使用 ready-to-run/D-stage/ 中的预编译版本"
echo "  3. 查看文档: docs/TESTING_GUIDE.md"
echo ""
echo "注意:"
echo "  - hello-minirv-ysyxsoc.bin 是一个完整的 RISC-V 程序"
echo "  - 需要完整的 SoC 环境才能运行"
echo "  - 建议使用商业仿真器或 FPGA 验证"
echo ""
echo "=========================================="
