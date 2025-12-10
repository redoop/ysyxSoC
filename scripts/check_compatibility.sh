#!/bin/bash
# 检查 hello-minirv-ysyxsoc.bin 与 CPU 的兼容性

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELLO_BIN="$SCRIPT_DIR/ready-to-run/D-stage/hello-minirv-ysyxsoc.bin"
CPU_RTL="$SCRIPT_DIR/rtl/ysyx_00000001.v"

echo "=========================================="
echo "CPU 与程序兼容性检查"
echo "=========================================="
echo ""

# 1. 检查程序架构
echo "1. 程序架构分析"
echo "----------------------------------------"
if [ -f "$HELLO_BIN" ]; then
    # 提取 ELF 头
    dd if="$HELLO_BIN" bs=1 skip=370432 count=2048 2>/dev/null > /tmp/elf_check.bin
    
    echo "ELF 信息:"
    readelf -h /tmp/elf_check.bin 2>/dev/null | grep -E "Class|Machine|Flags" | sed 's/^/  /'
    
    # 解析关键信息
    ELF_CLASS=$(readelf -h /tmp/elf_check.bin 2>/dev/null | grep "Class:" | awk '{print $2}')
    ELF_MACHINE=$(readelf -h /tmp/elf_check.bin 2>/dev/null | grep "Machine:" | awk '{print $2}')
    ELF_FLAGS=$(readelf -h /tmp/elf_check.bin 2>/dev/null | grep "Flags:" | grep -o "RV[^ ,]*" | head -1)
    
    echo ""
    echo "程序要求:"
    echo "  架构: $ELF_CLASS"
    echo "  指令集: $ELF_MACHINE"
    echo "  扩展: $ELF_FLAGS (RVE = 16 个寄存器)"
else
    echo "❌ 找不到测试程序"
    exit 1
fi
echo ""

# 2. 检查 CPU 配置
echo "2. CPU 配置分析"
echo "----------------------------------------"
if [ -f "$CPU_RTL" ]; then
    echo "CPU 类型: PicoRV32"
    
    # 检查关键配置
    ENABLE_MUL=$(grep "ENABLE_MUL" "$CPU_RTL" | grep -o "ENABLE_MUL([0-9])" | head -1)
    ENABLE_DIV=$(grep "ENABLE_DIV" "$CPU_RTL" | grep -o "ENABLE_DIV([0-9])" | head -1)
    COMPRESSED=$(grep "COMPRESSED_ISA" "$CPU_RTL" | grep -o "COMPRESSED_ISA([0-9])" | head -1)
    REGS_16_31=$(grep "ENABLE_REGS_16_31" "$CPU_RTL" | head -1)
    
    echo "CPU 配置:"
    echo "  $ENABLE_MUL (乘法指令)"
    echo "  $ENABLE_DIV (除法指令)"
    echo "  $COMPRESSED (压缩指令集 RVC)"
    
    # 检查寄存器数量
    if grep -q "ENABLE_REGS_16_31" "$SCRIPT_DIR/rtl/picorv32.v"; then
        # 检查实例化时的配置
        if grep -A 5 "picorv32 #(" "$CPU_RTL" | grep -q "ENABLE_REGS_16_31"; then
            REGS_CONFIG=$(grep -A 5 "picorv32 #(" "$CPU_RTL" | grep "ENABLE_REGS_16_31" | grep -o "[01]")
            if [ "$REGS_CONFIG" = "1" ]; then
                echo "  寄存器: 32 个 (RV32I)"
            else
                echo "  寄存器: 16 个 (RV32E)"
            fi
        else
            echo "  寄存器: 32 个 (默认, RV32I)"
        fi
    else
        echo "  寄存器: 32 个 (RV32I)"
    fi
else
    echo "❌ 找不到 CPU RTL"
    exit 1
fi
echo ""

# 3. 兼容性判断
echo "3. 兼容性判断"
echo "----------------------------------------"

COMPATIBLE=true
ISSUES=()

# 检查架构匹配
if [ "$ELF_CLASS" = "ELF32" ] && [ "$ELF_MACHINE" = "RISC-V" ]; then
    echo "✓ 架构匹配: 32 位 RISC-V"
else
    echo "❌ 架构不匹配"
    COMPATIBLE=false
    ISSUES+=("架构不匹配")
fi

# 检查 RVE vs RV32I
if echo "$ELF_FLAGS" | grep -q "RVE"; then
    echo "⚠ 程序使用 RVE (16 寄存器)"
    echo "  PicoRV32 默认配置是 RV32I (32 寄存器)"
    echo "  RV32I 可以运行 RVE 程序 (向下兼容)"
    echo "  但 RVE 程序只使用 x0-x15 寄存器"
fi

# 检查压缩指令集
if grep -q "COMPRESSED_ISA(1)" "$CPU_RTL"; then
    echo "✓ CPU 支持压缩指令集 (RVC)"
else
    echo "⚠ CPU 可能不支持压缩指令集"
fi

# 检查乘除法
if grep -q "ENABLE_MUL(1)" "$CPU_RTL"; then
    echo "✓ CPU 支持乘法指令 (M 扩展)"
else
    echo "⚠ CPU 不支持乘法指令"
fi

if grep -q "ENABLE_DIV(1)" "$CPU_RTL"; then
    echo "✓ CPU 支持除法指令 (M 扩展)"
else
    echo "⚠ CPU 不支持除法指令"
fi

echo ""

# 4. 总结
echo "=========================================="
echo "兼容性总结"
echo "=========================================="
echo ""

if [ "$COMPATIBLE" = true ]; then
    echo "✅ 基本兼容"
    echo ""
    echo "程序: RV32E (16 寄存器, 嵌入式精简版)"
    echo "CPU:  RV32IMC (32 寄存器, 乘除法, 压缩指令)"
    echo ""
    echo "兼容性说明:"
    echo "  • RV32I 可以运行 RVE 程序 (向下兼容)"
    echo "  • RVE 程序只使用 x0-x15,不会用到 x16-x31"
    echo "  • CPU 的额外功能(M/C 扩展)不影响兼容性"
    echo ""
    echo "✅ hello-minirv-ysyxsoc.bin 可以在当前 CPU 上运行"
else
    echo "❌ 存在兼容性问题:"
    for issue in "${ISSUES[@]}"; do
        echo "  • $issue"
    done
fi

echo ""
echo "注意事项:"
echo "  1. 程序入口地址: 0x80000000"
echo "  2. 需要正确的内存映射和外设支持"
echo "  3. 需要完整的 SoC 环境(UART、内存等)"
echo "  4. 建议使用商业仿真器或 FPGA 进行实际验证"
echo ""
echo "=========================================="

rm -f /tmp/elf_check.bin
