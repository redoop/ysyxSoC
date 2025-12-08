# 重新生成裁剪后的 RTL

## 已完成的修改

✓ 修改了 `src/SoC.scala` 第44行：
```scala
// 原来: 0x2000 (8KB, 2048x32)
// 现在: 0x800  (2KB, 512x32)
val sramNode = AXI4RAM(AddressSet.misaligned(0x0f000000, 0x800).head, ...)
```

## 重新生成步骤

### 1. 生成新的 Verilog
```bash
cd /opt/github/riscv-ai-accelerator/ecos/ysyxSoC
make verilog
```
**预计时间**: 5-10分钟

### 2. 验证生成结果
```bash
# 检查 RAM 大小
grep "mem_.*x32" build/ysyxSoCFull.v | head -1
# 应该显示: module mem_512x32(
```

### 3. 重新综合
```bash
cd synthesis
cp ../build/ysyxSoCFull.v rtl_export/
bash run_ics55_synthesis.sh
```
**预计时间**: 10-15分钟

### 4. 验证实例数量
```bash
./analyze_netlist.sh
```
**预期结果**: 约 50,000 个实例（减少75%）

## 预期改进

| 项目 | 修改前 | 修改后 |
|------|--------|--------|
| RAM 大小 | 8KB (2048x32) | 2KB (512x32) |
| 总实例数 | 202,574 | ~50,000 |
| 芯片面积 | 800,915 µm² | ~200,000 µm² |
| 建议芯片尺寸 | 3000x3000 | 1500x1500 |

## 如果还需要进一步裁剪

### 选项1: 减少到 256x32 (1KB)
```scala
val sramNode = AXI4RAM(AddressSet.misaligned(0x0f000000, 0x400).head, ...)
```
预期实例数: ~25,000

### 选项2: 完全移除片上 RAM
注释掉第44行和第51行中的 `sramNode`
预期实例数: ~15,000

### 选项3: 移除部分外设
注释掉不需要的外设（VGA、Keyboard等）
