# AI 加速器集成总结

## 完成的工作

已成功将两个 AI 加速器模块集成到 ysyxSoC 中：

### 1. 模块提取与重构
- ✅ 从 `EdgeAiSoCSimple.scala` 提取 `SimpleCompactAccel` 
- ✅ 从 `EdgeAiSoCSimple.scala` 提取 `SimpleBitNetAccel`
- ✅ 提取共享接口 `SimpleRegIO`
- ✅ 提取内存映射配置 `SimpleMemoryMap`
- ✅ 删除原始的 `EdgeAiSoCSimple.scala` 文件

### 2. 总线适配
- ✅ 创建 `APBAccelerators.scala` - APB 总线包装器
  - `APBCompactAccel` - CompactAccel 的 APB 包装
  - `APBBitNetAccel` - BitNetAccel 的 APB 包装
- ✅ 创建 `AXI4ToSimpleReg.scala` - AXI4 到 SimpleRegIO 桥接（备用）

### 3. SoC 集成
- ✅ 修改 `SoC.scala`，添加加速器实例
  - CompactAccel 映射到 0x10003000
  - BitNetAccel 映射到 0x10004000
- ✅ 连接到 APB 交叉开关
- ✅ 暴露中断信号到顶层

### 4. 文档与测试
- ✅ 创建 `README.md` - 详细的使用文档
- ✅ 创建 `test_accelerators.c` - C 语言测试程序
- ✅ 创建 `INTEGRATION.md` - 本集成总结

## 文件结构

```
ysyxSoC/src/ai/
├── SimpleRegIO.scala          # 简单寄存器接口定义
├── SimpleMemoryMap.scala      # 内存映射配置
├── SimpleCompactAccel.scala   # 标准矩阵乘法加速器
├── SimpleBitNetAccel.scala    # BitNet 加速器（无乘法器）
├── APBAccelerators.scala      # APB 总线包装器
├── AXI4ToSimpleReg.scala      # AXI4 桥接（备用）
├── README.md                  # 使用文档
├── INTEGRATION.md             # 本文档
└── test_accelerators.c        # C 测试程序
```

## 内存映射

| 外设 | 基地址 | 大小 | 描述 |
|------|--------|------|------|
| UART | 0x10000000 | 4KB | 串口控制器 |
| SPI | 0x10001000 | 4KB | SPI 控制器 |
| GPIO | 0x10002000 | 16B | GPIO 控制器 |
| **CompactAccel** | **0x10003000** | **4KB** | **标准矩阵加速器** |
| **BitNetAccel** | **0x10004000** | **4KB** | **BitNet 加速器** |
| Keyboard | 0x10011000 | 8B | PS/2 键盘 |
| MROM | 0x20000000 | 4KB | Mask ROM |
| VGA | 0x21000000 | 2MB | VGA 控制器 |
| Flash (XIP) | 0x30000000 | 256MB | SPI Flash |
| PSRAM | 0x80000000 | 4MB | PSRAM |
| SDRAM | 0xa0000000 | 32MB | SDRAM |

## 加速器特性对比

| 特性 | SimpleCompactAccel | SimpleBitNetAccel |
|------|-------------------|-------------------|
| 矩阵大小 | 2x2 到 8x8 | 2x2 到 8x8 |
| 数据类型 | 32-bit 无符号整数 | 32-bit 有符号整数 |
| 权重类型 | 任意值 | 仅 {-1, 0, +1} |
| 乘法器 | 使用硬件乘法器 | **无乘法器** |
| 稀疏性优化 | 无 | **自动跳过零权重** |
| 中断支持 | ✅ | ✅ |
| 性能计数器 | ✅ | ✅ + 稀疏性统计 |

## 使用流程

### 1. 编译 SoC
```bash
cd ysyxSoC
make
```

### 2. 编写软件
参考 `test_accelerators.c` 中的示例代码。

### 3. 基本使用步骤
```c
// 1. 设置矩阵大小
COMPACT_SIZE = 4;

// 2. 写入输入矩阵
for (int i = 0; i < 16; i++) {
    COMPACT_MATRIX_A[i] = ...;
    COMPACT_MATRIX_B[i] = ...;
}

// 3. 启动计算
COMPACT_CTRL = 1;

// 4. 等待完成
while (COMPACT_STATUS != 2);

// 5. 读取结果
for (int i = 0; i < 16; i++) {
    result[i] = COMPACT_MATRIX_C[i];
}
```

## 中断处理

两个加速器都支持完成中断：
- `compact_irq` - CompactAccel 完成中断
- `bitnet_irq` - BitNetAccel 完成中断

中断信号已暴露到 SoC 顶层，可以连接到 CPU 的中断控制器。

## 性能预估

### SimpleCompactAccel (8x8 矩阵)
- 计算量：8×8×8 = 512 次乘加
- 预估周期：~512 周期
- @100MHz：~5.12 μs

### SimpleBitNetAccel (8x8 矩阵)
- 计算量：最多 512 次加减
- 预估周期：~512 周期（最坏情况）
- 稀疏矩阵可显著减少周期数
- @100MHz：~5.12 μs（最坏情况）

## 验证状态

- ✅ 语法检查通过（无编译错误）
- ⏳ 功能仿真（待测试）
- ⏳ 硬件验证（待测试）
- ⏳ 性能测试（待测试）

## 下一步工作

1. **仿真测试**
   - 使用 Chisel 测试框架编写单元测试
   - 验证 APB 接口时序
   - 验证矩阵计算正确性

2. **集成测试**
   - 在完整 SoC 中运行测试程序
   - 验证中断功能
   - 性能基准测试

3. **优化**
   - 考虑添加 DMA 支持
   - 优化 APB 桥接延迟
   - 添加更多矩阵大小支持

4. **文档完善**
   - 添加时序图
   - 添加更多使用示例
   - 性能调优指南

## 技术细节

### APB 接口实现
- 使用状态机处理 APB 握手协议
- 支持 psel、penable 两阶段访问
- 自动处理 ready 信号

### 矩阵存储格式
- **CompactAccel**: 行优先，固定 8 列跨度
- **BitNetAccel**: 行优先，固定 16 列跨度
- 注意：即使矩阵小于最大尺寸，跨度仍然固定

### BitNet 权重编码
- 内部使用 2-bit 编码：
  - 00 = 0（跳过）
  - 01 = +1（加法）
  - 10 = -1（减法）
- 软件接口使用 32-bit 有符号整数
- 自动编码/解码

## 联系与支持

如有问题或建议，请参考：
- `README.md` - 详细使用文档
- `test_accelerators.c` - 测试示例
- SoC 源码注释

## 版本历史

- **v1.0** (2024-12-09)
  - 初始集成
  - 支持 CompactAccel 和 BitNetAccel
  - APB 总线接口
  - 基本文档和测试
