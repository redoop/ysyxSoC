#!/bin/bash
# 使用 ICS55 PDK 进行 ysyxSoCMinimal 逻辑综合

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 设置路径
YOSYS_BIN="/opt/tools/oss-cad/oss-cad-suite/bin/yosys"
PDK_ROOT="/opt/github/riscv-ai-accelerator/chisel/synthesis/pdk/icsprout55-pdk"
LIBERTY_FILE="$PDK_ROOT/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
VERILOG_MODEL="$PDK_ROOT/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/verilog/ics55_LLSC_H7CL.v"
RTL_FILE="../build/ysyxSoCMinimal.v"
OUTPUT_DIR="netlist"
NETLIST_FILE="$OUTPUT_DIR/ysyxSoCMinimal_ics55.v"

# 检查 RTL 文件
if [ ! -f "$RTL_FILE" ]; then
    echo "错误: 未找到 RTL 文件: $RTL_FILE"
    exit 1
fi

# 检查 PDK
if [ ! -f "$LIBERTY_FILE" ]; then
    echo "错误: 未找到 Liberty 文件: $LIBERTY_FILE"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

echo "=========================================="
echo "ysyxSoCMinimal ICS55 逻辑综合"
echo "=========================================="
echo "RTL: $RTL_FILE"
echo "输出: $NETLIST_FILE"
echo ""

# 创建 Yosys 综合脚本
cat > /tmp/ics55_synth_minimal.ys << EOF
# 读取外部模块
read_verilog -sv ../rtl/picorv32.v
read_verilog -sv ../rtl/ysyx_00000001.v
read_verilog -sv ../perip/amba/apb_delayer.v
read_verilog -sv ../perip/uart16550/rtl/uart_defines.v
read_verilog -sv ../perip/uart16550/rtl/raminfr.v
read_verilog -sv ../perip/uart16550/rtl/uart_sync_flops.v
read_verilog -sv ../perip/uart16550/rtl/uart_rfifo.v
read_verilog -sv ../perip/uart16550/rtl/uart_tfifo.v
read_verilog -sv ../perip/uart16550/rtl/uart_receiver.v
read_verilog -sv ../perip/uart16550/rtl/uart_transmitter.v
read_verilog -sv ../perip/uart16550/rtl/uart_regs.v
read_verilog -sv ../perip/uart16550/rtl/uart_top_apb.v

# 读取 RTL
read_verilog -sv $RTL_FILE

# 设置顶层模块
hierarchy -top ysyxSoCMinimal
hierarchy -check

# 将大型存储器标记为黑盒（不综合）
blackbox mem_16384x32
blackbox activation_256x32
blackbox weight_256x2
blackbox result_256x32
blackbox matrix_64x32

# 综合流程
proc
opt
fsm
opt
memory
opt
techmap
opt

# 映射到 ICS55 标准单元
dfflibmap -liberty $LIBERTY_FILE
abc -liberty $LIBERTY_FILE -D 10000

# 清理
clean

# 统计
tee -o $OUTPUT_DIR/synthesis_stats_minimal.txt stat -liberty $LIBERTY_FILE

# 输出网表
write_verilog -noattr -noexpr $NETLIST_FILE
EOF

echo "运行 Yosys 综合..."
$YOSYS_BIN /tmp/ics55_synth_minimal.ys 2>&1 | tee "$OUTPUT_DIR/synthesis_minimal.log"

if [ -f "$NETLIST_FILE" ]; then
    echo ""
    echo "✓ 综合成功！"
    echo "网表文件: $NETLIST_FILE"
    echo ""
    wc -l "$NETLIST_FILE"
    
    # 复制标准单元模型
    cp "$VERILOG_MODEL" "$OUTPUT_DIR/ics55_LLSC_H7CL.v"
    echo "✓ 已复制标准单元 Verilog 模型"
else
    echo ""
    echo "✗ 综合失败，请查看日志: $OUTPUT_DIR/synthesis_minimal.log"
    exit 1
fi
