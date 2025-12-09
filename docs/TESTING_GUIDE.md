# AI 加速器测试指南

本指南介绍如何测试项目中新增的 AI 加速器模块。

---

## 快速开始

### 1. 编译检查
```bash
cd /opt/github/riscv-ai-accelerator/ecos/ysyxSoC
mill ysyxsoc.compile
```
**预期结果**: 编译成功，无错误

### 2. 生成 Verilog
```bash
make verilog
```
**预期结果**: 生成 `build/ysyxSoCFull.v`

### 3. 运行功能测试
```bash
python3 src/ai/test_functionality.py
```
**预期结果**: 所有测试通过

### 4. 验证 Verilog
```bash
bash src/ai/verify_verilog.sh
```
**预期结果**: 找到所有加速器模块

---

## 详细测试步骤

### 测试 1: 编译验证

**目的**: 验证 Scala 代码无语法错误

**命令**:
```bash
mill ysyxsoc.compile
```

**检查点**:
- ✅ 编译成功
- ✅ 无错误信息
- ✅ 无警告信息

**预期输出**:
```
[info] Compiling...
[success] Compilation completed
```

---

### 测试 2: Verilog 生成

**目的**: 验证能够生成完整的 SoC Verilog

**命令**:
```bash
make verilog
```

**检查点**:
- ✅ 生成 `build/ysyxSoCFull.v`
- ✅ 文件大小 > 200KB
- ✅ 包含加速器模块

**验证**:
```bash
ls -lh build/ysyxSoCFull.v
grep -c "module SimpleCompactAccel\|module SimpleBitNetAccel" build/ysyxSoCFull.v
```

**预期输出**:
```
-rw-rw-r-- 1 user user 209K Dec  9 11:44 build/ysyxSoCFull.v
2
```

---

### 测试 3: 功能测试

**目的**: 验证加速器的数学功能正确性

**命令**:
```bash
python3 src/ai/test_functionality.py
```

**测试内容**:

#### CompactAccel 测试
1. 2x2 单位矩阵乘法
2. 4x4 单位矩阵乘法
3. 4x4 一般矩阵乘法
4. 8x8 矩阵乘法（最大尺寸）

#### BitNetAccel 测试
1. 4x4 单位矩阵（+1 权重）
2. 稀疏权重矩阵（81.2% 稀疏度）
3. 混合三值权重
4. 全负权重
5. 8x8 矩阵（最大尺寸）

**检查点**:
- ✅ 所有矩阵乘法结果正确
- ✅ 稀疏性优化工作正常
- ✅ 性能估算合理

**预期输出**:
```
============================================================
AI 加速器功能测试
============================================================
...
✓ 期望结果应该等于 A
...
✓ 稀疏度: 81.2% (13/16 个零)
...
============================================================
所有测试完成！
============================================================
```

---

### 测试 4: Verilog 验证

**目的**: 验证生成的 Verilog 包含所有必要的模块

**命令**:
```bash
bash src/ai/verify_verilog.sh
```

**检查点**:
- ✅ SimpleCompactAccel 模块存在
- ✅ SimpleBitNetAccel 模块存在
- ✅ APBCompactAccel 包装器存在
- ✅ APBBitNetAccel 包装器存在
- ✅ 模块实例化正确

**预期输出**:
```
=== 验证 Verilog 生成 ===

✓ 找到 Verilog 文件: build/ysyxSoCFull.v

检查 SimpleCompactAccel 模块...
✓ 找到 SimpleCompactAccel 模块 (行 1514)
检查 SimpleBitNetAccel 模块...
✓ 找到 SimpleBitNetAccel 模块 (行 1763)
...
=== ✅ Verilog 验证通过 ===
```

---

## 高级测试

### 测试 5: 模块位置查找

**目的**: 查找加速器模块在 Verilog 中的位置

**命令**:
```bash
grep -n "module SimpleCompactAccel\|module SimpleBitNetAccel" build/ysyxSoCFull.v
```

**预期输出**:
```
1514:module SimpleCompactAccel(
1763:module SimpleBitNetAccel(
```

---

### 测试 6: 信号检查

**目的**: 验证关键信号存在

**命令**:
```bash
# 检查 CompactAccel 矩阵缓冲区
grep "matrixA\|matrixB\|matrixC" build/ysyxSoCFull.v | head -5

# 检查 BitNetAccel 缓冲区
grep "activation\|weight\|result" build/ysyxSoCFull.v | head -5
```

---

### 测试 7: APB 连接验证

**目的**: 验证 APB 总线连接

**命令**:
```bash
grep -A 10 "APBCompactAccel lcompact" build/ysyxSoCFull.v
grep -A 10 "APBBitNetAccel lbitnet" build/ysyxSoCFull.v
```

**检查点**:
- ✅ clock 和 reset 连接
- ✅ APB 信号连接（psel, penable, pwrite, paddr, pwdata, prdata, pready）

---

## 测试矩阵

| 测试项 | 命令 | 预期结果 | 状态 |
|-------|------|---------|------|
| 编译检查 | `mill ysyxsoc.compile` | 编译成功 | ✅ |
| Verilog 生成 | `make verilog` | 生成文件 | ✅ |
| 功能测试 | `python3 src/ai/test_functionality.py` | 所有测试通过 | ✅ |
| Verilog 验证 | `bash src/ai/verify_verilog.sh` | 模块存在 | ✅ |
| 模块位置 | `grep -n "module Simple" build/ysyxSoCFull.v` | 找到模块 | ✅ |
| 信号检查 | `grep "matrix" build/ysyxSoCFull.v` | 找到信号 | ✅ |
| APB 连接 | `grep "APB.*Accel" build/ysyxSoCFull.v` | 找到实例 | ✅ |

---

## 故障排除

### 问题 1: 编译失败

**症状**: `mill ysyxsoc.compile` 报错

**可能原因**:
- Scala 语法错误
- 依赖缺失
- Mill 版本不兼容

**解决方案**:
```bash
# 检查 Mill 版本
cat .mill-version

# 清理并重新编译
mill clean
mill ysyxsoc.compile
```

---

### 问题 2: Verilog 生成失败

**症状**: `make verilog` 失败或生成的文件不包含加速器

**可能原因**:
- 编译未完成
- SoC.scala 未正确集成加速器

**解决方案**:
```bash
# 确保编译成功
mill ysyxsoc.compile

# 检查 SoC.scala
grep "CompactAccel\|BitNetAccel" src/SoC.scala

# 重新生成
make clean
make verilog
```

---

### 问题 3: 功能测试失败

**症状**: Python 测试脚本报错

**可能原因**:
- NumPy 未安装
- Python 版本不兼容

**解决方案**:
```bash
# 安装 NumPy
pip3 install numpy

# 检查 Python 版本
python3 --version

# 重新运行测试
python3 src/ai/test_functionality.py
```

---

### 问题 4: 找不到模块

**症状**: `verify_verilog.sh` 报告找不到模块

**可能原因**:
- Verilog 未生成
- 模块名称不匹配

**解决方案**:
```bash
# 检查文件是否存在
ls -lh build/ysyxSoCFull.v

# 手动搜索模块
grep "module.*Accel" build/ysyxSoCFull.v

# 重新生成 Verilog
make verilog
```

---

## 性能测试

### 估算性能

**命令**:
```bash
python3 src/ai/test_functionality.py | grep "性能估算" -A 20
```

**预期输出**:
```
性能估算
============================================================

CompactAccel:
  2x2 矩阵: ~8 周期, ~0.08 μs, ~12500000 矩阵/秒
  4x4 矩阵: ~64 周期, ~0.64 μs, ~1562500 矩阵/秒
  8x8 矩阵: ~512 周期, ~5.12 μs, ~195312 矩阵/秒

BitNetAccel (50%稀疏度):
  2x2 矩阵: ~4 周期, ~0.04 μs, ~25000000 矩阵/秒
  4x4 矩阵: ~32 周期, ~0.32 μs, ~3125000 矩阵/秒
  8x8 矩阵: ~256 周期, ~2.56 μs, ~390625 矩阵/秒
```

---

## 下一步测试

### RTL 仿真（Verilator）

**准备工作**:
```bash
# 安装 Verilator
sudo apt-get install verilator

# 创建测试台
# 参考 src/ai/test_compact_accel.v
```

**运行仿真**:
```bash
verilator --cc build/ysyxSoCFull.v --exe test_bench.cpp
make -C obj_dir -f VysyxSoCFull.mk
./obj_dir/VysyxSoCFull
```

---

### C 程序测试

**编译测试程序**:
```bash
riscv64-unknown-elf-gcc -march=rv64imac -mabi=lp64 \
    -o test_accelerators.elf src/ai/test_accelerators.c
```

**在模拟器上运行**:
```bash
# 使用 Spike 或其他 RISC-V 模拟器
spike --isa=rv64imac test_accelerators.elf
```

---

### FPGA 综合

**准备工作**:
- 选择目标 FPGA（如 Xilinx Artix-7）
- 准备约束文件
- 配置时钟和 I/O

**综合命令**:
```bash
# 使用 Vivado 或 Quartus
vivado -mode batch -source synth.tcl
```

---

## 测试报告

所有测试完成后，查看以下报告：

1. **TEST_SUMMARY.md** - 测试总结
2. **TEST_RESULTS.md** - 详细测试结果
3. **COMPREHENSIVE_TEST_REPORT.md** - 综合测试报告

---

## 联系和支持

如有问题，请查看：
- README.md - 使用文档
- QUICKSTART.md - 快速开始
- INTEGRATION.md - 集成说明

---

**最后更新**: 2024-12-09  
**测试环境**: Mill 0.12.4, Chisel 7.0.0-M2, Scala 2.13.14
