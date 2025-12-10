#!/bin/bash
# 快速修复 iEDA netlist_opt 崩溃问题

echo "=========================================="
echo "iEDA netlist_opt 问题修复工具"
echo "=========================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"

# 选项
echo "选择修复方案:"
echo ""
echo "1. 生成简化版设计 (推荐 - 快速验证)"
echo "2. 生成仅 AI 加速器版本"
echo "3. 显示在线 iEDA 推荐参数"
echo "4. 检查当前设计复杂度"
echo "5. 生成分层综合脚本"
echo ""
read -p "请选择 (1-5): " choice

case $choice in
  1)
    echo ""
    echo "生成简化版设计..."
    cat > "$BUILD_DIR/ysyxSoC_simple.v" << 'EOF'
// 简化版 ysyxSoC - 用于验证 iEDA 流程
module ysyxSoC_simple(
  input clock,
  input reset,
  output reg [31:0] test_output
);

  // 简单计数器
  reg [31:0] counter;
  
  always @(posedge clock) begin
    if (reset) begin
      counter <= 32'h0;
      test_output <= 32'h0;
    end else begin
      counter <= counter + 1;
      test_output <= counter;
    end
  end

  // 可以添加一个简化的 AI 加速器实例用于测试
  // CompactAccel accel(...);

endmodule
EOF
    echo "✓ 已生成: $BUILD_DIR/ysyxSoC_simple.v"
    echo ""
    echo "使用方法:"
    echo "  1. 上传 ysyxSoC_simple.v 到在线 iEDA"
    echo "  2. 设置 top_name = ysyxSoC_simple"
    echo "  3. 其他参数保持默认"
    ;;
    
  2)
    echo ""
    echo "提取 AI 加速器模块..."
    
    if [ ! -f "$BUILD_DIR/ysyxSoCFull.v" ]; then
      echo "❌ 找不到 ysyxSoCFull.v"
      exit 1
    fi
    
    # 提取 CompactAccel
    sed -n '/^module CompactAccel/,/^endmodule/p' "$BUILD_DIR/ysyxSoCFull.v" > "$BUILD_DIR/ai_accelerators.v"
    
    # 提取 BitNetAccel
    sed -n '/^module BitNetAccel/,/^endmodule/p' "$BUILD_DIR/ysyxSoCFull.v" >> "$BUILD_DIR/ai_accelerators.v"
    
    # 创建测试顶层
    cat >> "$BUILD_DIR/ai_accelerators.v" << 'EOF'

// AI 加速器测试顶层
module ai_accel_test(
  input clock,
  input reset,
  // 简化的 APB 接口
  input [31:0] paddr,
  input pwrite,
  input psel,
  input penable,
  input [31:0] pwdata,
  output reg [31:0] prdata,
  output reg pready
);

  // CompactAccel 信号
  wire [31:0] compact_prdata;
  wire compact_pready;
  wire compact_sel = psel && (paddr[16:12] == 5'h3);
  
  // BitNetAccel 信号  
  wire [31:0] bitnet_prdata;
  wire bitnet_pready;
  wire bitnet_sel = psel && (paddr[16:12] == 5'h4);
  
  // 实例化加速器
  CompactAccel compact_accel(
    .clock(clock),
    .reset(reset),
    .io_apb_PADDR(paddr),
    .io_apb_PWRITE(pwrite),
    .io_apb_PSEL(compact_sel),
    .io_apb_PENABLE(penable),
    .io_apb_PWDATA(pwdata),
    .io_apb_PRDATA(compact_prdata),
    .io_apb_PREADY(compact_pready)
  );
  
  BitNetAccel bitnet_accel(
    .clock(clock),
    .reset(reset),
    .io_apb_PADDR(paddr),
    .io_apb_PWRITE(pwrite),
    .io_apb_PSEL(bitnet_sel),
    .io_apb_PENABLE(penable),
    .io_apb_PWDATA(pwdata),
    .io_apb_PRDATA(bitnet_prdata),
    .io_apb_PREADY(bitnet_pready)
  );
  
  // 输出选择
  always @(*) begin
    if (compact_sel) begin
      prdata = compact_prdata;
      pready = compact_pready;
    end else if (bitnet_sel) begin
      prdata = bitnet_prdata;
      pready = bitnet_pready;
    end else begin
      prdata = 32'h0;
      pready = 1'b1;
    end
  end

endmodule
EOF
    
    echo "✓ 已生成: $BUILD_DIR/ai_accelerators.v"
    echo ""
    echo "使用方法:"
    echo "  1. 上传 ai_accelerators.v 到在线 iEDA"
    echo "  2. 设置 top_name = ai_accel_test"
    ;;
    
  3)
    echo ""
    echo "=========================================="
    echo "在线 iEDA 推荐参数"
    echo "=========================================="
    echo ""
    cat << 'EOF'
{
  "top_name": "ysyxSoCFull",
  "clk_port_name": "clock",
  "clk_freq_mhz": 30,           ← 降低到 30MHz
  "core_util": 0.15,            ← 降低利用率
  "die_bbox": "0 0 300 300",    ← 增大芯片面积
  "core_bbox": "30 30 270 270",
  "target_density": 0.25,       ← 降低密度
  "max_fanout": 16,             ← 降低扇出限制
  "max_iterative": 1000,        ← 减少迭代
  "fast_route": true,           ← 启用快速模式
  "fast_signoff": true
}
EOF
    echo ""
    echo "关键修改:"
    echo "  • 时钟频率: 50MHz → 30MHz"
    echo "  • 核心利用率: 0.2 → 0.15"
    echo "  • 最大扇出: 32 → 16"
    echo "  • 芯片面积: 100x100 → 300x300"
    ;;
    
  4)
    echo ""
    echo "检查设计复杂度..."
    
    if [ ! -f "$BUILD_DIR/ysyxSoCFull.v" ]; then
      echo "❌ 找不到 ysyxSoCFull.v"
      exit 1
    fi
    
    echo ""
    echo "设计统计:"
    echo "----------------------------------------"
    
    MODULE_COUNT=$(grep -c "^module " "$BUILD_DIR/ysyxSoCFull.v")
    WIRE_COUNT=$(grep -c "wire " "$BUILD_DIR/ysyxSoCFull.v")
    REG_COUNT=$(grep -c "reg " "$BUILD_DIR/ysyxSoCFull.v")
    ALWAYS_COUNT=$(grep -c "always @" "$BUILD_DIR/ysyxSoCFull.v")
    
    echo "  模块数量: $MODULE_COUNT"
    echo "  Wire 数量: $WIRE_COUNT"
    echo "  Reg 数量: $REG_COUNT"
    echo "  Always 块: $ALWAYS_COUNT"
    echo ""
    
    # 检查大模块
    echo "大型模块 (>100行):"
    awk '/^module / {name=$2; start=NR} /^endmodule/ {if(NR-start>100) print "  " name ": " (NR-start) " 行"}' "$BUILD_DIR/ysyxSoCFull.v"
    echo ""
    
    # 评估
    if [ $MODULE_COUNT -gt 30 ]; then
      echo "⚠ 设计较复杂,建议使用简化版本"
    else
      echo "✓ 设计规模适中"
    fi
    ;;
    
  5)
    echo ""
    echo "生成分层综合脚本..."
    
    cat > "$SCRIPT_DIR/synthesis/hierarchical_synth.tcl" << 'EOF'
# 分层综合脚本 - 避免过度展平

# 读取设计
read_verilog ysyxSoCFull.v

# 设置层次结构
hierarchy -check -top ysyxSoCFull

# 不展平设计
# flatten 会导致设计过大

# 分别综合各个模块
synth -top CompactAccel -flatten 0
synth -top BitNetAccel -flatten 0
synth -top picorv32 -flatten 0

# 综合顶层
synth -top ysyxSoCFull -flatten 0

# 映射到工艺库
dfflibmap -liberty ics55_lib.lib
abc -liberty ics55_lib.lib

# 输出
write_verilog -noattr ysyxSoCFull_hierarchical.v
EOF
    
    echo "✓ 已生成: synthesis/hierarchical_synth.tcl"
    echo ""
    echo "使用方法:"
    echo "  cd synthesis"
    echo "  yosys hierarchical_synth.tcl"
    ;;
    
  *)
    echo "无效选择"
    exit 1
    ;;
esac

echo ""
echo "=========================================="
echo "完成!"
echo "=========================================="
