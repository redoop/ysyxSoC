# iEDA netlist_opt 崩溃问题修复指南

## 问题描述

```
ERROR: Command 'iEDA' died with <Signals.SIGABRT: 6>
步骤: netlist_opt (网表优化 - fix_fanout)
耗时: 0.79秒 (立即崩溃)
```

## 根本原因

iEDA 的 netlist_opt 工具在处理大型/复杂设计时崩溃,可能原因:

1. **设计规模过大**: ysyxSoCFull 包含 CPU + 7个外设 + 2个AI加速器
2. **扇出过高**: 某些信号扇出超过工具限制
3. **内存布局问题**: 工具内部断言失败
4. **网表结构问题**: Yosys 生成的网表与 iEDA 不兼容

## 解决方案

### 方案 1: 调整在线 iEDA 参数 ⭐ 推荐

在提交任务时修改参数:

```json
{
  "max_fanout": 16,          // 从 32 降低到 16
  "core_util": 0.15,         // 从 0.2 降低到 0.15
  "target_density": 0.25,    // 从 0.3 降低到 0.25
  "die_bbox": "0 0 200 200", // 增大芯片面积
  "core_bbox": "20 20 180 180"
}
```

**原理**: 降低密度和扇出限制,给工具更多优化空间。

### 方案 2: 简化设计

#### 2.1 移除非关键外设

编辑 `build/ysyxSoCFull.v`,注释掉:
- VGA 控制器 (大量逻辑)
- SDRAM 控制器 (复杂状态机)
- PS/2 控制器

保留:
- CPU (ysyx_00000001)
- AI 加速器 (CompactAccel, BitNetAccel)
- UART (用于调试)
- 基本内存

#### 2.2 创建最小测试版本

```bash
cd /opt/github/riscv-ai-accelerator/ecos/ysyxSoC

# 创建仅包含 AI 加速器的测试版本
cat > build/ysyxSoC_ai_only.v << 'EOF'
module ysyxSoC_ai_only(
  input clock,
  input reset,
  // AXI 接口 (简化)
  input [31:0] axi_awaddr,
  input axi_awvalid,
  output axi_awready,
  input [31:0] axi_wdata,
  input axi_wvalid,
  output axi_wready
);

  // 实例化 AI 加速器
  // CompactAccel 和 BitNetAccel
  // (从 ysyxSoCFull.v 中提取)

endmodule
EOF
```

### 方案 3: 修改综合策略

#### 3.1 添加综合约束

创建 `synthesis/constraints.tcl`:

```tcl
# 限制扇出
set_max_fanout 16 [current_design]

# 设置时钟约束 (放宽)
create_clock -period 30.0 [get_ports clock]  # 33MHz 而不是 50MHz

# 设置面积约束
set_max_area 0  # 不限制面积,优先功能

# 禁用某些优化
set_flatten false
set_structure false
```

在 Yosys 综合时使用:
```bash
yosys -s synthesis/constraints.tcl
```

#### 3.2 分层综合

不要展平整个设计,保持层次结构:

```tcl
# 在 Yosys 中
hierarchy -check -top ysyxSoCFull
# 不要使用 flatten
synth -top ysyxSoCFull -flatten 0
```

### 方案 4: 使用其他工具

如果 iEDA 持续失败,考虑:

1. **Yosys + OpenROAD** (开源完整流程)
2. **商业工具** (Synopsys DC + ICC2)
3. **仅综合验证** (不做 P&R)

## 快速测试步骤

### 测试 1: 最小设计

```bash
# 1. 创建最小测试
cat > test_minimal.v << 'EOF'
module test_minimal(
  input clock,
  input reset,
  output reg [7:0] counter
);
  always @(posedge clock)
    if (reset) counter <= 0;
    else counter <= counter + 1;
endmodule
EOF

# 2. 提交到在线 iEDA
# 参数: top_name=test_minimal, clk_freq=50
```

如果最小设计通过,说明是设计规模问题。

### 测试 2: 仅 AI 加速器

```bash
# 提取 AI 加速器模块
grep -A 1000 "module CompactAccel" build/ysyxSoCFull.v > test_ai.v
grep -A 1000 "module BitNetAccel" build/ysyxSoCFull.v >> test_ai.v

# 创建简单的顶层
cat >> test_ai.v << 'EOF'
module test_ai_top(
  input clock,
  input reset
);
  // 实例化加速器
  CompactAccel accel1(...);
  BitNetAccel accel2(...);
endmodule
EOF
```

## 本地代码修改建议

### 修改 1: 降低默认扇出

编辑 `src/SoC.scala` 或相关配置:

```scala
// 在 AXI 总线配置中
val maxFanout = 16  // 从 32 降低

// 在时钟树配置中
val clockBufferSize = "small"  // 使用小缓冲
```

### 修改 2: 简化外设

编辑 `src/SoC.scala`:

```scala
// 注释掉非必需外设
// val vga = LazyModule(new VGAController)
// val sdram = LazyModule(new SDRAMController)

// 仅保留
val uart = LazyModule(new UARTController)
val compactAccel = LazyModule(new CompactAccel)
val bitnetAccel = LazyModule(new BitNetAccel)
```

### 修改 3: 添加综合指令

在 `Makefile` 中:

```makefile
# 添加综合选项
SYNTH_OPTS = -flatten 0 -max_fanout 16

verilog: $(V_FILE_FINAL)
	# 后处理: 插入缓冲器
	@python3 scripts/insert_buffers.py $@
```

## 调试技巧

### 1. 检查综合报告

```bash
# 查看综合后的统计
cat /taskData/task_4798/00_synthesis/ysyxSoCFull_synth_stat.json

# 关注:
# - num_cells: 单元数量
# - cell_area: 面积
# - 高扇出网络
```

### 2. 查看网表

```bash
# 检查综合后的网表
head -100 /taskData/task_4798/00_synthesis/ysyxSoCFull_nl.v

# 查找高扇出信号
grep -E "assign.*\[.*:.*\]" ysyxSoCFull_nl.v
```

### 3. 逐步验证

```bash
# 1. 先验证综合
make verilog

# 2. 手动运行 netlist_opt (如果有本地 iEDA)
iEDA -script test_netlist_opt.tcl

# 3. 查看详细日志
tail -f ieda.log
```

## 推荐的完整流程

### 阶段 1: 验证设计正确性
```bash
cd /opt/github/riscv-ai-accelerator/ecos/ysyxSoC
./verify_design.sh
./check_compatibility.sh
```

### 阶段 2: 本地综合测试
```bash
# 使用 Yosys 本地综合
cd synthesis
./run_ics55_synthesis.sh
```

### 阶段 3: 在线 iEDA (调整参数)
```json
{
  "top_name": "ysyxSoCFull",
  "clk_freq_mhz": 30,        // 降低频率
  "core_util": 0.15,         // 降低利用率
  "max_fanout": 16,          // 降低扇出
  "die_bbox": "0 0 300 300", // 增大面积
  "fast_route": true,        // 快速布线
  "fast_signoff": true
}
```

### 阶段 4: 如果仍失败
- 使用简化版本 (仅 AI 加速器)
- 或使用 OpenROAD 完整流程
- 或仅做综合验证,不做 P&R

## 联系支持

如果问题持续:
1. 导出综合后的网表
2. 提供给 iEDA 团队分析
3. 或使用其他 EDA 工具

---

**关键建议**: 
- ⭐ 先降低参数重试 (max_fanout=16, core_util=0.15)
- ⭐ 如果失败,使用简化设计验证流程
- ⭐ 最终目标是验证 AI 加速器功能,不一定需要完整 SoC
