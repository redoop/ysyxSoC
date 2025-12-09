#!/bin/bash
# 验证生成的 Verilog 文件中包含加速器模块

echo "=== 验证 Verilog 生成 ==="
echo ""

VERILOG_FILE="build/ysyxSoCFull.v"

if [ ! -f "$VERILOG_FILE" ]; then
    echo "❌ 错误: 找不到 $VERILOG_FILE"
    echo "请先运行: make verilog"
    exit 1
fi

echo "✓ 找到 Verilog 文件: $VERILOG_FILE"
echo ""

# 检查 SimpleCompactAccel 模块
echo "检查 SimpleCompactAccel 模块..."
if grep -q "module SimpleCompactAccel" "$VERILOG_FILE"; then
    LINE=$(grep -n "module SimpleCompactAccel" "$VERILOG_FILE" | head -1 | cut -d: -f1)
    echo "✓ 找到 SimpleCompactAccel 模块 (行 $LINE)"
else
    echo "❌ 未找到 SimpleCompactAccel 模块"
    exit 1
fi

# 检查 SimpleBitNetAccel 模块
echo "检查 SimpleBitNetAccel 模块..."
if grep -q "module SimpleBitNetAccel" "$VERILOG_FILE"; then
    LINE=$(grep -n "module SimpleBitNetAccel" "$VERILOG_FILE" | head -1 | cut -d: -f1)
    echo "✓ 找到 SimpleBitNetAccel 模块 (行 $LINE)"
else
    echo "❌ 未找到 SimpleBitNetAccel 模块"
    exit 1
fi

# 检查 APBCompactAccel 模块
echo "检查 APBCompactAccel 包装器..."
if grep -q "module APBCompactAccel" "$VERILOG_FILE"; then
    LINE=$(grep -n "module APBCompactAccel" "$VERILOG_FILE" | head -1 | cut -d: -f1)
    echo "✓ 找到 APBCompactAccel 包装器 (行 $LINE)"
else
    echo "❌ 未找到 APBCompactAccel 包装器"
    exit 1
fi

# 检查 APBBitNetAccel 模块
echo "检查 APBBitNetAccel 包装器..."
if grep -q "module APBBitNetAccel" "$VERILOG_FILE"; then
    LINE=$(grep -n "module APBBitNetAccel" "$VERILOG_FILE" | head -1 | cut -d: -f1)
    echo "✓ 找到 APBBitNetAccel 包装器 (行 $LINE)"
else
    echo "❌ 未找到 APBBitNetAccel 包装器"
    exit 1
fi

# 检查实例化
echo ""
echo "检查模块实例化..."
if grep -q "APBCompactAccel lcompact" "$VERILOG_FILE"; then
    echo "✓ 找到 CompactAccel 实例化"
else
    echo "❌ 未找到 CompactAccel 实例化"
    exit 1
fi

if grep -q "APBBitNetAccel lbitnet" "$VERILOG_FILE"; then
    echo "✓ 找到 BitNetAccel 实例化"
else
    echo "❌ 未找到 BitNetAccel 实例化"
    exit 1
fi

# 统计信息
echo ""
echo "=== 统计信息 ==="
echo "文件大小: $(wc -c < "$VERILOG_FILE") 字节"
echo "总行数: $(wc -l < "$VERILOG_FILE") 行"
echo "模块数量: $(grep -c "^module " "$VERILOG_FILE") 个"
echo ""

# 检查关键信号
echo "=== 检查关键信号 ==="
echo "CompactAccel 寄存器:"
grep "matrixA\|matrixB\|matrixC" "$VERILOG_FILE" | head -3 | sed 's/^/  /'
echo ""
echo "BitNetAccel 寄存器:"
grep "activation\|weight\|result" "$VERILOG_FILE" | head -3 | sed 's/^/  /'
echo ""

echo "=== ✅ Verilog 验证通过 ==="
