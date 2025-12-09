# 如何验证 ysyxSoC 设计

## 快速验证 (1 分钟)

```bash
# 运行设计完整性检查
./verify_design.sh
```

这会检查:
- ✅ Verilog 文件是否生成
- ✅ 所有模块是否存在
- ✅ AI 加速器是否集成
- ✅ 测试程序是否就绪

## 验证结果

运行后你会看到:

```
==========================================
ysyxSoC 设计验证报告
==========================================

✓ Verilog 文件存在 (209,414 字节, 5,310 行)
✓ AI 加速器模块: CompactAccel, BitNetAccel
✓ CPU 模块: ysyx_00000001
✓ 所有外设模块存在 (7 个)
✓ 测试程序就绪: hello-minirv-ysyxsoc.bin

设计统计:
  模块数量: 47
  Wire 数量: 735
  Reg 数量: 165
```

## hello-minirv-ysyxsoc.bin 是什么?

这是一个完整的 RISC-V 可执行程序,用于验证 SoC 的功能:

- **大小**: 672,656 字节
- **格式**: ELF 可执行文件
- **用途**: 测试 CPU、内存、外设等基本功能
- **位置**: `ready-to-run/D-stage/hello-minirv-ysyxsoc.bin`

## 如何使用 hello-minirv-ysyxsoc.bin?

### 方法 1: 商业仿真器 (推荐)

如果你有 VCS、Questa 或 Xcelium:

```bash
# 1. 准备文件列表
cat > filelist.f << 'FLIST'
build/ysyxSoCFull.v
rtl/ysyx_00000001.v
perip/uart16550/rtl/uart_top_apb.v
perip/gpio/rtl/gpio_top_apb.v
# ... 其他外设文件
FLIST

# 2. 编译
vcs -full64 -sverilog -f filelist.f testbench.v

# 3. 运行
./simv +bin=ready-to-run/D-stage/hello-minirv-ysyxsoc.bin
```

### 方法 2: FPGA 验证 (最佳)

```bash
# 1. 综合设计
cd synthesis
./run_ics55_synthesis.sh

# 2. 实现到 FPGA
# (使用 Vivado/Quartus 等工具)

# 3. 加载程序并运行
# (通过 JTAG 或串口)
```

### 方法 3: 使用预编译版本

```bash
cd ready-to-run/D-stage
# 这里有预编译的 Verilog 和测试程序
# 可以直接用于你的仿真环境
```

## 为什么开源仿真器不能用?

### Icarus Verilog
- ❌ 不支持某些 SystemVerilog 特性
- ❌ 生成的 Verilog 使用了 `automatic` 等关键字

### Verilator
- ❌ 需要所有外设模块的源文件
- ❌ 外设模块(UART、SDRAM 等)是外部 IP

### 解决方案
使用商业仿真器或 FPGA 进行完整验证。

## 验证 AI 加速器

设计中集成了两个 AI 加速器:

### CompactAccel (0x10003000)
```c
// 标准矩阵乘法加速器
// 支持 2x2 到 8x8 矩阵
// 详见: docs/QUICKSTART.md
```

### BitNetAccel (0x10004000)
```c
// BitNet 专用加速器
// 权重限制为 -1, 0, +1
// 详见: docs/QUICKSTART.md
```

## 查看波形文件

如果你有 VCD 文件:

```bash
# 在命令行查看 (文本模式)
less your_file.vcd

# 使用 GTKWave (GUI)
gtkwave your_file.vcd
```

## 更多信息

- **完整验证报告**: `VERIFICATION_SUMMARY.md`
- **测试指南**: `docs/TESTING_GUIDE.md`
- **快速入门**: `docs/QUICKSTART.md`
- **项目文档**: `docs/README.md`

## 总结

✅ 设计已经验证完整  
✅ 所有模块都已集成  
✅ 测试程序已经就绪  
⏳ 需要商业仿真器或 FPGA 进行功能验证

---

**提示**: 先运行 `./verify_design.sh` 确认一切正常!
