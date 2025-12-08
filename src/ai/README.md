# AI 加速器集成文档

## 概述

本目录包含两个 AI 加速器模块，已集成到 ysyxSoC 中：

1. **SimpleCompactAccel** - 标准矩阵乘法加速器
2. **SimpleBitNetAccel** - BitNet 加速器（无乘法器设计）

## 内存映射

| 模块 | 基地址 | 大小 | 描述 |
|------|--------|------|------|
| CompactAccel | 0x10003000 | 4KB | 标准矩阵乘法加速器 |
| BitNetAccel | 0x10004000 | 4KB | BitNet 加速器 |

## SimpleCompactAccel 寄存器映射

### 控制寄存器
- **0x000**: CTRL - 控制寄存器
  - bit[0]: START - 写1开始计算
- **0x004**: STATUS - 状态寄存器
  - 0: 空闲
  - 1: 计算中
  - 2: 完成
- **0x01C**: MATRIX_SIZE - 矩阵大小 (2-8)
- **0x028**: PERF_CYCLES - 性能计数器（周期数）

### 数据缓冲区
- **0x100-0x1FF**: 矩阵 A (64个32位元素)
- **0x300-0x3FF**: 矩阵 B (64个32位元素)
- **0x500-0x5FF**: 矩阵 C (64个32位元素，只读)

### 使用示例（C代码）
```c
#define COMPACT_BASE 0x10003000
#define COMPACT_CTRL     (*(volatile uint32_t*)(COMPACT_BASE + 0x000))
#define COMPACT_STATUS   (*(volatile uint32_t*)(COMPACT_BASE + 0x004))
#define COMPACT_SIZE     (*(volatile uint32_t*)(COMPACT_BASE + 0x01C))
#define COMPACT_CYCLES   (*(volatile uint32_t*)(COMPACT_BASE + 0x028))
#define COMPACT_MATRIX_A ((volatile uint32_t*)(COMPACT_BASE + 0x100))
#define COMPACT_MATRIX_B ((volatile uint32_t*)(COMPACT_BASE + 0x300))
#define COMPACT_MATRIX_C ((volatile uint32_t*)(COMPACT_BASE + 0x500))

void compact_matmul_4x4() {
    // 设置矩阵大小
    COMPACT_SIZE = 4;
    
    // 写入矩阵 A (4x4)
    for (int i = 0; i < 16; i++) {
        COMPACT_MATRIX_A[i] = i + 1;
    }
    
    // 写入矩阵 B (4x4 单位矩阵)
    for (int i = 0; i < 16; i++) {
        COMPACT_MATRIX_B[i] = (i % 5 == 0) ? 1 : 0;
    }
    
    // 启动计算
    COMPACT_CTRL = 1;
    
    // 等待完成
    while (COMPACT_STATUS != 2);
    
    // 读取结果
    for (int i = 0; i < 16; i++) {
        uint32_t result = COMPACT_MATRIX_C[i];
        // 处理结果...
    }
    
    // 读取性能计数
    uint32_t cycles = COMPACT_CYCLES;
}
```

## SimpleBitNetAccel 寄存器映射

### 控制寄存器
- **0x000**: CTRL - 控制寄存器
  - bit[0]: START - 写1开始计算
- **0x004**: STATUS - 状态寄存器
  - 0: 空闲
  - 1: 计算中
  - 2: 完成
  - 3: 错误
- **0x01C**: MATRIX_SIZE - 矩阵大小 (2-8)
- **0x020**: CONFIG - 配置寄存器
- **0x028**: PERF_CYCLES - 性能计数器
- **0x02C**: SPARSITY_SKIPPED - 跳过的零权重计数
- **0x030**: ERROR_CODE - 错误代码

### 数据缓冲区
- **0x100-0x2FF**: 激活值 (256个32位有符号整数)
- **0x300-0x4FF**: 权重 (256个值，编码为 -1/0/+1)
- **0x500-0x8FF**: 结果 (256个32位有符号整数，只读)

### BitNet 权重编码
- 写入 0 表示权重为 0（跳过）
- 写入 1 表示权重为 +1（加法）
- 写入 -1 (0xFFFFFFFF) 表示权重为 -1（减法）

### 使用示例（C代码）
```c
#define BITNET_BASE 0x10004000
#define BITNET_CTRL     (*(volatile uint32_t*)(BITNET_BASE + 0x000))
#define BITNET_STATUS   (*(volatile uint32_t*)(BITNET_BASE + 0x004))
#define BITNET_SIZE     (*(volatile uint32_t*)(BITNET_BASE + 0x01C))
#define BITNET_CYCLES   (*(volatile uint32_t*)(BITNET_BASE + 0x028))
#define BITNET_SKIPPED  (*(volatile uint32_t*)(BITNET_BASE + 0x02C))
#define BITNET_ERROR    (*(volatile uint32_t*)(BITNET_BASE + 0x030))
#define BITNET_ACTIVATION ((volatile int32_t*)(BITNET_BASE + 0x100))
#define BITNET_WEIGHT     ((volatile int32_t*)(BITNET_BASE + 0x300))
#define BITNET_RESULT     ((volatile int32_t*)(BITNET_BASE + 0x500))

void bitnet_matmul_4x4() {
    // 设置矩阵大小
    BITNET_SIZE = 4;
    
    // 写入激活值 (4x4)
    for (int i = 0; i < 16; i++) {
        BITNET_ACTIVATION[i] = i + 1;
    }
    
    // 写入 BitNet 权重 (4x4, 只有 -1, 0, +1)
    int32_t weights[16] = {
        1, 0, -1, 1,
        0, 1, 0, -1,
        -1, 0, 1, 0,
        1, -1, 0, 1
    };
    for (int i = 0; i < 16; i++) {
        BITNET_WEIGHT[i] = weights[i];
    }
    
    // 启动计算
    BITNET_CTRL = 1;
    
    // 等待完成
    while (BITNET_STATUS == 1);
    
    // 检查错误
    if (BITNET_STATUS == 3) {
        uint32_t error = BITNET_ERROR;
        // 处理错误...
        return;
    }
    
    // 读取结果
    for (int i = 0; i < 16; i++) {
        int32_t result = BITNET_RESULT[i];
        // 处理结果...
    }
    
    // 读取性能统计
    uint32_t cycles = BITNET_CYCLES;
    uint32_t skipped = BITNET_SKIPPED;  // 稀疏性优化统计
}
```

## 中断支持

两个加速器都支持中断：
- **compact_irq**: CompactAccel 完成中断
- **bitnet_irq**: BitNetAccel 完成中断

中断在计算完成时触发，可以连接到 CPU 的中断控制器。

## 性能特性

### SimpleCompactAccel
- 支持 2x2 到 8x8 矩阵
- 使用硬件乘法器
- 每周期执行一次乘加操作
- 8x8 矩阵乘法约需 512 周期

### SimpleBitNetAccel
- 支持 2x2 到 8x8 矩阵
- **无乘法器设计**（只用加减法）
- 权重限制为 {-1, 0, +1}
- 自动跳过零权重（稀疏性优化）
- 8x8 矩阵乘法约需 512 周期（最坏情况）
- 稀疏矩阵可显著减少周期数

## 文件结构

```
src/ai/
├── README.md                  # 本文档
├── SimpleRegIO.scala          # 简单寄存器接口定义
├── SimpleMemoryMap.scala      # 内存映射配置
├── SimpleCompactAccel.scala   # 标准矩阵加速器
├── SimpleBitNetAccel.scala    # BitNet 加速器
├── APBAccelerators.scala      # APB 总线包装器
└── AXI4ToSimpleReg.scala      # AXI4 到 SimpleRegIO 桥接
```

## 集成说明

加速器已通过 APB 总线集成到 ysyxSoC 中：
1. 使用 APB 从设备接口
2. 通过 APBAccelerators.scala 包装
3. 在 SoC.scala 中实例化并连接到 APB 交叉开关
4. 中断信号暴露到顶层

## 测试

建议的测试步骤：
1. 单元测试：测试单个加速器模块
2. 集成测试：通过 APB 总线访问加速器
3. 性能测试：测量不同矩阵大小的计算时间
4. 中断测试：验证中断信号正确触发

## 注意事项

1. 矩阵存储为行优先格式
2. CompactAccel 固定使用 8 列跨度（即使矩阵小于 8x8）
3. BitNetAccel 固定使用 16 列跨度
4. 写入超出范围的矩阵大小会被自动限制或产生错误
5. 计算过程中不要修改输入矩阵
6. 读取结果前确保状态为"完成"
