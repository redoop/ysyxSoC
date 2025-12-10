# 精简版 ysyxSoC 构建指南

## 目标

生成 <10,000 门的精简版 SoC,适配 iEDA 工具能力。

## 设计裁剪策略

### 保留的模块

✅ **核心功能**:
- CPU (简化配置)
- CompactAccel (AI 加速器)
- BitNetAccel (AI 加速器)
- UART (基本调试)
- 小容量 SRAM (64KB)

### 移除的模块

❌ **复杂外设**:
- ChipLink (复杂互连)
- VGA 控制器
- PS/2 控制器
- GPIO
- SPI
- PSRAM
- SDRAM
- Flash

❌ **复杂总线**:
- 多级 crossbar
- 复杂的 AXI 互连

## 构建步骤

### 1. 编译精简版

```bash
cd /opt/github/riscv-ai-accelerator/ecos/ysyxSoC
./build_minimal.sh
```

### 2. 检查输出

```bash
# 查看生成的文件
ls -lh build/ysyxSoCMinimal.v

# 检查模块
grep "^module " build/ysyxSoCMinimal.v
```

### 3. 上传到 iEDA

**文件**: `build/ysyxSoCMinimal.v`

**参数**:
```json
{
  "top_name": "ysyxSoCTopMinimal",
  "clk_port_name": "clock",
  "clk_freq_mhz": 50,
  "core_util": 0.3,
  "max_fanout": 32,
  "die_bbox": "0 0 200 200",
  "core_bbox": "20 20 180 180"
}
```

## 代码结构

### 新增文件

1. **src/SoCMinimal.scala**
   - 精简版 SoC 定义
   - 只包含核心模块
   - 简化的总线结构

2. **src/TopMinimal.scala**
   - 精简版顶层模块
   - 简化的 I/O 接口

3. **build_minimal.sh**
   - 自动化构建脚本
   - 统计信息输出

### 修改说明

#### SoCMinimal.scala

```scala
class ysyxSoCMinimal(implicit p: Parameters) extends LazyModule {
  // 简化的总线
  val xbar = AXI4Xbar()
  val apbxbar = LazyModule(new APBFanout).node
  
  // 简化的 CPU
  val cpu = LazyModule(new CPU(idBits = 4))
  
  // 只保留必需外设
  val luart = LazyModule(new APBUart16550(...))
  val lcompact = LazyModule(new APBCompactAccel(...))
  val lbitnet = LazyModule(new APBBitNetAccel(...))
  
  // 小容量 SRAM
  val sramNode = AXI4RAM(..., 0x10000) // 64KB
  
  // 简化的连接
  List(luart.node, lcompact.node, lbitnet.node).map(_ := apbxbar)
  List(apbxbar := ... := AXI4ToAPB() := ..., sramNode).map(_ := xbar)
  xbar := ... := cpu.masterNode
}
```

#### 关键优化

1. **减少 ID 位宽**: `idBits = 4` (原来可能更大)
2. **移除 ChipLink**: 不需要 FPGA 互连
3. **单级总线**: 只有一个 AXI crossbar
4. **小容量内存**: 64KB SRAM (原来可能更大)
5. **最少外设**: 只保留 UART 和 AI 加速器

## 预期结果

### 设计规模

```
模块数量: ~15 (vs 原来 47)
行数: ~2000 (vs 原来 5310)
估算门数: ~8000 (vs 原来 >50000)
```

### iEDA 兼容性

- ✅ 门数 < 10,000
- ✅ 模块数量适中
- ✅ 总线结构简单
- ✅ 扇出可控

## 验证步骤

### 1. 本地验证

```bash
# 编译检查
mill -i ysyxsoc.compile

# 生成 Verilog
./build_minimal.sh

# 检查输出
cat build/ysyxSoCMinimal.v | head -100
```

### 2. iEDA 验证

1. 上传 `build/ysyxSoCMinimal.v`
2. 设置 `top_name = ysyxSoCTopMinimal`
3. 使用推荐参数
4. 运行完整流程

### 3. 功能验证

虽然移除了大部分外设,但核心功能保留:
- ✅ CPU 可以执行指令
- ✅ AI 加速器可以工作
- ✅ UART 可以调试
- ✅ 内存可以访问

## 故障排除

### 问题 1: 编译失败

**原因**: 依赖关系问题

**解决**:
```bash
# 清理缓存
mill clean
# 重新编译
mill -i ysyxsoc.compile
```

### 问题 2: 门数仍然过大

**解决**: 进一步裁剪

1. 减少 SRAM 容量
2. 简化 CPU 配置
3. 移除 UART (如果不需要调试)

### 问题 3: AI 加速器缺失

**检查**:
```bash
grep -i "compact\|bitnet" build/ysyxSoCMinimal.v
```

**原因**: 可能是连接问题

**解决**: 检查 `SoCMinimal.scala` 中的连接

## 与完整版对比

| 特性 | 完整版 | 精简版 |
|------|--------|--------|
| 模块数 | 47 | ~15 |
| 门数 | >50K | <10K |
| 外设 | 7个 | 1个 |
| AI 加速器 | 2个 | 2个 |
| 内存 | 多种 | 64KB SRAM |
| 总线 | 多级 | 单级 |
| iEDA 兼容 | ✗ | ✅ |

## 后续优化

如果精简版成功:

1. **逐步添加外设**
   - 先加 GPIO
   - 再加 SPI
   - 最后加 VGA

2. **增加内存**
   - 从 64KB 增加到 256KB
   - 添加 PSRAM 支持

3. **优化性能**
   - 提高时钟频率
   - 优化总线宽度

## 总结

精简版 ysyxSoC 通过大幅裁剪外设和简化总线,将设计规模降低到 iEDA 可处理的范围,同时保留了核心的 AI 加速器功能。

**关键**: 先验证核心功能,再逐步添加外设。

---

**构建命令**: `./build_minimal.sh`  
**输出文件**: `build/ysyxSoCMinimal.v`  
**目标门数**: <10,000
