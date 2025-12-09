# AI 加速器快速入门

## 🚀 5 分钟上手指南

### 内存地址
```c
#define COMPACT_BASE  0x10003000  // 标准矩阵加速器
#define BITNET_BASE   0x10004000  // BitNet 加速器
```

### CompactAccel - 最简示例

```c
#include <stdint.h>

#define COMPACT_BASE 0x10003000
#define CTRL   (*(volatile uint32_t*)(COMPACT_BASE + 0x000))
#define STATUS (*(volatile uint32_t*)(COMPACT_BASE + 0x004))
#define SIZE   (*(volatile uint32_t*)(COMPACT_BASE + 0x01C))
#define MAT_A  ((volatile uint32_t*)(COMPACT_BASE + 0x100))
#define MAT_B  ((volatile uint32_t*)(COMPACT_BASE + 0x300))
#define MAT_C  ((volatile uint32_t*)(COMPACT_BASE + 0x500))

void matmul_2x2() {
    SIZE = 2;  // 2x2 矩阵
    
    // A = [1 2]    B = [1 0]
    //     [3 4]        [0 1]
    MAT_A[0] = 1; MAT_A[1] = 2;
    MAT_A[8] = 3; MAT_A[9] = 4;
    
    MAT_B[0] = 1; MAT_B[1] = 0;
    MAT_B[8] = 0; MAT_B[9] = 1;
    
    CTRL = 1;  // 启动
    while (STATUS != 2);  // 等待完成
    
    // 结果在 MAT_C
    uint32_t c00 = MAT_C[0];  // = 1
    uint32_t c01 = MAT_C[1];  // = 2
    uint32_t c10 = MAT_C[8];  // = 3
    uint32_t c11 = MAT_C[9];  // = 4
}
```

### BitNetAccel - 最简示例

```c
#include <stdint.h>

#define BITNET_BASE 0x10004000
#define CTRL   (*(volatile uint32_t*)(BITNET_BASE + 0x000))
#define STATUS (*(volatile uint32_t*)(BITNET_BASE + 0x004))
#define SIZE   (*(volatile uint32_t*)(BITNET_BASE + 0x01C))
#define ACT    ((volatile int32_t*)(BITNET_BASE + 0x100))
#define WEIGHT ((volatile int32_t*)(BITNET_BASE + 0x300))
#define RESULT ((volatile int32_t*)(BITNET_BASE + 0x500))

void bitnet_2x2() {
    SIZE = 2;  // 2x2 矩阵
    
    // Activation = [1 2]
    //              [3 4]
    ACT[0] = 1; ACT[1] = 2;
    ACT[16] = 3; ACT[17] = 4;
    
    // Weight = [1  0]  (只能是 -1, 0, +1)
    //          [0 -1]
    WEIGHT[0] = 1; WEIGHT[1] = 0;
    WEIGHT[16] = 0; WEIGHT[17] = -1;
    
    CTRL = 1;  // 启动
    while (STATUS == 1);  // 等待完成
    
    // 结果在 RESULT
    int32_t r00 = RESULT[0];   // = 1
    int32_t r01 = RESULT[1];   // = -2
    int32_t r10 = RESULT[16];  // = 3
    int32_t r11 = RESULT[17];  // = -4
}
```

## 📋 寄存器速查表

### CompactAccel
| 偏移 | 名称 | 读/写 | 说明 |
|------|------|-------|------|
| 0x000 | CTRL | W | bit[0]=1 启动 |
| 0x004 | STATUS | R | 0=空闲, 1=计算中, 2=完成 |
| 0x01C | SIZE | R/W | 矩阵大小 (2-8) |
| 0x028 | CYCLES | R | 性能计数器 |
| 0x100-0x1FF | MAT_A | W | 矩阵 A (64个元素) |
| 0x300-0x3FF | MAT_B | W | 矩阵 B (64个元素) |
| 0x500-0x5FF | MAT_C | R | 矩阵 C (64个元素) |

### BitNetAccel
| 偏移 | 名称 | 读/写 | 说明 |
|------|------|-------|------|
| 0x000 | CTRL | W | bit[0]=1 启动 |
| 0x004 | STATUS | R | 0=空闲, 1=计算中, 2=完成, 3=错误 |
| 0x01C | SIZE | R/W | 矩阵大小 (2-8) |
| 0x028 | CYCLES | R | 性能计数器 |
| 0x02C | SKIPPED | R | 跳过的零权重数 |
| 0x030 | ERROR | R | 错误代码 |
| 0x100-0x2FF | ACT | R/W | 激活值 (256个) |
| 0x300-0x4FF | WEIGHT | R/W | 权重 (256个, 仅 -1/0/+1) |
| 0x500-0x8FF | RESULT | R | 结果 (256个) |

## ⚠️ 重要提示

### 矩阵索引
```c
// CompactAccel: 行跨度 = 8
matrix[row][col] = MAT_A[row * 8 + col];

// BitNetAccel: 行跨度 = 16
matrix[row][col] = ACT[row * 16 + col];
```

### BitNet 权重限制
```c
// ✅ 正确
WEIGHT[i] = -1;  // 减法
WEIGHT[i] = 0;   // 跳过
WEIGHT[i] = 1;   // 加法

// ❌ 错误
WEIGHT[i] = 2;   // 会被转换为 +1
WEIGHT[i] = -5;  // 会被转换为 -1
```

### 状态检查
```c
// ✅ 正确
while (STATUS != 2);  // 等待完成

// ❌ 错误
while (STATUS == 1);  // 可能错过完成状态
```

## 🔧 调试技巧

### 1. 检查状态
```c
if (STATUS == 3) {
    printf("Error: %u\n", ERROR);
}
```

### 2. 性能分析
```c
uint32_t cycles = CYCLES;
printf("Computation took %u cycles\n", cycles);
```

### 3. 稀疏性统计（BitNet）
```c
uint32_t skipped = SKIPPED;
printf("Skipped %u zero weights\n", skipped);
```

## 📚 更多信息

- 详细文档：`README.md`
- 完整示例：`test_accelerators.c`
- 集成说明：`INTEGRATION.md`

## 🎯 性能参考

| 矩阵大小 | 预估周期 | @100MHz |
|---------|---------|---------|
| 2x2 | ~8 | ~80 ns |
| 4x4 | ~64 | ~640 ns |
| 8x8 | ~512 | ~5.12 μs |

**注意**：BitNet 在稀疏矩阵上可以更快！
