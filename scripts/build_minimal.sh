#!/bin/bash
# 构建精简版 ysyxSoC (<10K 门)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "构建精简版 ysyxSoC"
echo "目标: <10,000 门,适配 iEDA"
echo "=========================================="
echo ""

# 1. 编译 Scala 代码
echo "1. 编译 Scala 代码..."
mill -i ysyxsoc.compile

if [ $? -ne 0 ]; then
    echo "❌ 编译失败"
    exit 1
fi
echo "✓ 编译成功"
echo ""

# 2. 生成 Verilog
echo "2. 生成精简版 Verilog..."
mkdir -p build/minimal
mill -i ysyxsoc.runMain ysyx.ElaborateMinimal --target-dir build/minimal

if [ $? -ne 0 ]; then
    echo "❌ Verilog 生成失败"
    exit 1
fi
echo "✓ Verilog 生成成功"
echo ""

# 3. 后处理
echo "3. 后处理 Verilog..."
VERILOG_FILE="build/minimal/ysyxSoCTopMinimal.sv"

if [ ! -f "$VERILOG_FILE" ]; then
    echo "❌ 找不到生成的 Verilog 文件"
    exit 1
fi

# 复制并重命名
cp "$VERILOG_FILE" "build/ysyxSoCMinimal.v"

# 清理不需要的文件
sed -i '/firrtl_black_box_resource_files.f/,$ d' build/ysyxSoCMinimal.v

# 添加 BlackBox 实现 (ysyx_00000001)
cat >> build/ysyxSoCMinimal.v << 'BBOX'

// BlackBox 实现由外部 Verilog 文件提供
// 需要包含: ysyx_00000001.v, picorv32.v
BBOX

echo "✓ 后处理完成"
echo ""

# 4. 统计信息
echo "4. 设计统计"
echo "----------------------------------------"
FILE_SIZE=$(stat -f%z "build/ysyxSoCMinimal.v" 2>/dev/null || stat -c%s "build/ysyxSoCMinimal.v" 2>/dev/null)
LINE_COUNT=$(wc -l < "build/ysyxSoCMinimal.v")
MODULE_COUNT=$(grep -c "^module " "build/ysyxSoCMinimal.v")

echo "  文件大小: $FILE_SIZE 字节"
echo "  行数: $LINE_COUNT"
echo "  模块数: $MODULE_COUNT"
echo ""

# 估算门数
REG_COUNT=$(grep -c "reg " "build/ysyxSoCMinimal.v")
WIRE_COUNT=$(grep -c "wire " "build/ysyxSoCMinimal.v")
ALWAYS_COUNT=$(grep -c "always " "build/ysyxSoCMinimal.v")

ESTIMATED_GATES=$((REG_COUNT * 6 + ALWAYS_COUNT * 10))

echo "  寄存器: $REG_COUNT"
echo "  Wire: $WIRE_COUNT"
echo "  Always 块: $ALWAYS_COUNT"
echo "  估算门数: ~$ESTIMATED_GATES"
echo ""

if [ $ESTIMATED_GATES -lt 10000 ]; then
    echo "✓ 门数估算 < 10,000,符合 iEDA 要求"
else
    echo "⚠ 门数估算 > 10,000,可能仍然过大"
fi
echo ""

# 5. 检查关键模块
echo "5. 检查关键模块"
echo "----------------------------------------"
if grep -q "CompactAccel" "build/ysyxSoCMinimal.v"; then
    echo "  ✓ CompactAccel 存在"
else
    echo "  ❌ CompactAccel 缺失"
fi

if grep -q "BitNetAccel" "build/ysyxSoCMinimal.v"; then
    echo "  ✓ BitNetAccel 存在"
else
    echo "  ❌ BitNetAccel 缺失"
fi

if grep -q "uart" "build/ysyxSoCMinimal.v"; then
    echo "  ✓ UART 存在"
else
    echo "  ❌ UART 缺失"
fi

if grep -q "ysyx_00000001_BlackBox" "build/ysyxSoCMinimal.v"; then
    echo "  ✓ CPU BlackBox 存在"
else
    echo "  ⚠ CPU BlackBox 未找到"
fi
echo ""

echo "=========================================="
echo "构建完成!"
echo "输出文件: build/ysyxSoCMinimal.v"
echo "=========================================="
echo ""
echo "下一步:"
echo "  1. ./export_minimal.sh (导出所有文件)"
echo "  2. cd minimal_export && zip -r ysyxSoCMinimal.zip *"
echo "  3. 上传到在线 iEDA"
echo ""
echo "iEDA 参数:"
echo "  top_name: ysyxSoCTopMinimal"
echo "  clk_port_name: clock"
