#!/bin/bash
# 使用 ICS55 PDK 进行逻辑综合
# 生成可以用 Icarus Verilog 仿真的网表

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 设置路径
YOSYS_BIN="/opt/tools/oss-cad/oss-cad-suite/bin/yosys"
PDK_ROOT="/opt/github/riscv-ai-accelerator/chisel/synthesis/pdk/icsprout55-pdk"
# 使用 H7CL (Low) 标准单元库，典型角度
LIBERTY_FILE="$PDK_ROOT/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
VERILOG_MODEL="$PDK_ROOT/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/verilog/ics55_LLSC_H7CL.v"
RTL_FILE="../build/ysyxSoCFull.v"
SDC_FILE="fpga/constraints/timing_complete.sdc"
OUTPUT_DIR="netlist"
NETLIST_FILE="$OUTPUT_DIR/ysyxSoCFull_ics55.v"

# 检查 RTL 文件
if [ ! -f "$RTL_FILE" ]; then
    echo "错误: 未找到 RTL 文件: $RTL_FILE"
    echo "请先生成 Chisel RTL"
    exit 1
fi

# 检查 PDK 是否存在
if [ ! -d "$PDK_ROOT" ]; then
    echo "错误: 未找到 ICS55 PDK"
    echo "请运行: python pdk/get_ics55_pdk.py"
    exit 1
fi

if [ ! -f "$LIBERTY_FILE" ]; then
    echo "错误: 未找到 ICS55 PDK Liberty 文件: $LIBERTY_FILE"
    echo "请检查 PDK 安装"
    exit 1
fi

if [ ! -f "$VERILOG_MODEL" ]; then
    echo "错误: 未找到 ICS55 PDK Verilog 模型: $VERILOG_MODEL"
    echo "请检查 PDK 安装"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

echo "=========================================="
echo "ICS55 PDK 逻辑综合 (带 SDC 约束)"
echo "=========================================="
echo "PDK: ICS55"
echo "Liberty: $LIBERTY_FILE"
echo "Verilog: $VERILOG_MODEL"
echo "RTL: $RTL_FILE"
echo "SDC: $SDC_FILE"
echo "输出: $NETLIST_FILE"
echo ""

# 检查 SDC 文件
if [ ! -f "$SDC_FILE" ]; then
    echo "警告: 未找到 SDC 约束文件: $SDC_FILE"
    echo "将不使用时序约束进行综合"
    SDC_CONSTRAINT=""
else
    echo "✓ 找到 SDC 约束文件"
    # 注意: Yosys 的 abc 命令支持 -constr 参数读取 SDC
    # 但功能有限，主要用于时序驱动的优化
    SDC_CONSTRAINT="-constr $SDC_FILE"
fi

# 创建 Yosys 综合脚本
cat > /tmp/ics55_synth.ys << EOF
# 加载 slang 插件以支持完整的 SystemVerilog
plugin -i slang

# 读取外设 RTL (使用修复后的文件)
read_slang \\
    ../rtl/picorv32.v \\
    ../rtl/ysyx_00000001.v \\
    ../perip/amba/apb_delayer.v \\
    ../perip/bitrev/bitrev.v \\
    ../perip/flash/flash_fixed.v \\
    ../perip/gpio/gpio_top_apb.v \\
    ../perip/ps2/ps2_top_apb.v \\
    ../perip/psram/efabless/EF_PSRAM_CTRL_wb.v \\
    ../perip/psram/efabless/EF_PSRAM_CTRL.v \\
    ../perip/psram/psram.v \\
    ../perip/psram/psram_top_apb.v \\
    ../perip/sdram/sdram.v \\
    ../perip/sdram/sdram_top_apb_fixed.v \\
    ../perip/sdram/core_sdram_axi4/sdram_axi_core.v \\
    ../perip/spi/rtl/spi_defines.v \\
    ../perip/spi/rtl/spi_clgen.v \\
    ../perip/spi/rtl/spi_shift.v \\
    ../perip/spi/rtl/spi_top.v \\
    ../perip/spi/rtl/spi_top_apb.v \\
    ../perip/uart16550/rtl/uart_defines.v \\
    ../perip/uart16550/rtl/raminfr.v \\
    ../perip/uart16550/rtl/uart_sync_flops.v \\
    ../perip/uart16550/rtl/uart_rfifo.v \\
    ../perip/uart16550/rtl/uart_tfifo.v \\
    ../perip/uart16550/rtl/uart_receiver.v \\
    ../perip/uart16550/rtl/uart_transmitter.v \\
    ../perip/uart16550/rtl/uart_regs.v \\
    ../perip/uart16550/rtl/uart_top_apb.v \\
    ../perip/vga/vga_top_apb.v \\
    $RTL_FILE \\
    --top ysyxSoCFull \\
    --compat-mode --keep-hierarchy \\
    --allow-use-before-declare --ignore-unknown-modules \\
    --ignore-timing --ignore-initial

# 设置顶层模块
hierarchy -top ysyxSoCFull
hierarchy -check

# 综合流程
proc
opt
fsm
opt
memory
opt
techmap
opt

# 映射到 ICS55 标准单元（带时序约束）
dfflibmap -liberty $LIBERTY_FILE
abc -liberty $LIBERTY_FILE $SDC_CONSTRAINT -D 10000

# 清理
clean

# 统计
tee -o $OUTPUT_DIR/synthesis_stats_ics55.txt stat -liberty $LIBERTY_FILE

# 输出网表
write_verilog -noattr -noexpr $NETLIST_FILE

# 如果有 SDC 文件，复制到输出目录
EOF

if [ -f "$SDC_FILE" ]; then
    echo "cp $SDC_FILE $OUTPUT_DIR/timing_constraints.sdc" >> /tmp/ics55_synth.ys
fi

echo "运行 Yosys 综合..."
$YOSYS_BIN /tmp/ics55_synth.ys 2>&1 | tee "$OUTPUT_DIR/synthesis_ics55.log"

if [ -f "$NETLIST_FILE" ]; then
    echo ""
    echo "✓ 综合成功！"
    echo "网表文件: $NETLIST_FILE"
    echo ""
    echo "网表统计:"
    wc -l "$NETLIST_FILE"
    echo ""
    
    # 复制 Verilog 模型到 netlist 目录以便仿真
    cp "$VERILOG_MODEL" "$OUTPUT_DIR/ics55_LLSC_H7CL.v"
    echo "✓ 已复制标准单元 Verilog 模型"
    
    # 复制 SDC 约束文件
    if [ -f "$SDC_FILE" ]; then
        cp "$SDC_FILE" "$OUTPUT_DIR/timing_constraints.sdc"
        echo "✓ 已复制 SDC 约束文件"
    fi
    echo ""
    
    echo "下一步:"
    echo "  1. 运行后综合仿真:"
    echo "     python run_post_syn_sim.py --simulator iverilog --netlist ics55"
    echo ""
    echo "  2. 运行静态时序分析 (需要 OpenSTA):"
    echo "     sta -f $OUTPUT_DIR/timing_constraints.sdc $NETLIST_FILE"
else
    echo ""
    echo "✗ 综合失败，请查看日志: $OUTPUT_DIR/synthesis_ics55.log"
    exit 1
fi
