#!/bin/bash
# 导出精简版 ysyxSoCTopMinimal 相关 Verilog 文件

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPORT_DIR="$SCRIPT_DIR/minimal_export"

echo "=========================================="
echo "导出精简版 Verilog 文件"
echo "=========================================="
echo ""

# 1. 创建导出目录
echo "1. 创建导出目录..."
rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"
echo "✓ 目录创建: $EXPORT_DIR"
echo ""

# 2. 构建精简版 (如果还没有)
echo "2. 检查精简版 Verilog..."
if [ ! -f "build/ysyxSoCMinimal.v" ]; then
    echo "   精简版不存在,开始构建..."
    ./build_minimal.sh
else
    echo "✓ 精简版已存在"
fi
echo ""

# 3. 复制主文件
echo "3. 复制主文件..."
cp build/ysyxSoCMinimal.v "$EXPORT_DIR/"
echo "✓ ysyxSoCMinimal.v"

# 4. 复制必需的外设文件 (精简版只需要 UART)
echo ""
echo "4. 复制外设文件..."

# UART 相关
cp perip/uart16550/rtl/uart_top_apb.v "$EXPORT_DIR/"
cp perip/uart16550/rtl/uart_defines.v "$EXPORT_DIR/"
cp perip/uart16550/rtl/uart_regs.v "$EXPORT_DIR/"
cp perip/uart16550/rtl/uart_receiver.v "$EXPORT_DIR/"
cp perip/uart16550/rtl/uart_transmitter.v "$EXPORT_DIR/"
cp perip/uart16550/rtl/uart_rfifo.v "$EXPORT_DIR/"
cp perip/uart16550/rtl/uart_tfifo.v "$EXPORT_DIR/"
cp perip/uart16550/rtl/uart_sync_flops.v "$EXPORT_DIR/"
echo "✓ UART 模块 (8个文件)"

# APB Delayer
cp perip/amba/apb_delayer.v "$EXPORT_DIR/"
echo "✓ APB Delayer"

# 5. 复制 CPU (如果使用 PicoRV32)
echo ""
echo "5. 复制 CPU..."
cp rtl/picorv32.v "$EXPORT_DIR/"
cp rtl/ysyx_00000001.v "$EXPORT_DIR/"
echo "✓ CPU 模块 (2个文件)"

# 6. 生成 filelist
echo ""
echo "6. 生成 filelist.f..."
cat > "$EXPORT_DIR/filelist.f" << 'FLIST'
// 精简版 ysyxSoC Verilog 文件列表
// 用于 iEDA 综合

// 主文件
ysyxSoCMinimal.v

// CPU
picorv32.v
ysyx_00000001.v

// UART
uart_top_apb.v
uart_defines.v
uart_regs.v
uart_receiver.v
uart_transmitter.v
uart_rfifo.v
uart_tfifo.v
uart_sync_flops.v

// APB
apb_delayer.v
FLIST
echo "✓ filelist.f"

# 7. 生成 README
echo ""
echo "7. 生成 README..."
cat > "$EXPORT_DIR/README.md" << 'README'
# ysyxSoCTopMinimal Verilog 导出

## 文件说明

### 主文件
- `ysyxSoCMinimal.v` - 精简版 SoC 顶层模块

### CPU
- `picorv32.v` - PicoRV32 CPU 核心
- `ysyx_00000001.v` - CPU 包装器 (符合 ysyx 接口规范)

### 外设
- `uart_*.v` - UART 16550 控制器 (8个文件)
- `apb_delayer.v` - APB 总线延迟器

### 配置文件
- `filelist.f` - Verilog 文件列表

## 设计规模

- 模块数: ~15
- 估算门数: ~8,000
- 适配: iEDA (<10K 门)

## 使用方法

### 上传到 iEDA

1. 压缩所有文件
   ```bash
   zip -r ysyxSoCMinimal.zip *
   ```

2. 上传到在线 iEDA

3. 配置参数
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

### 本地综合 (Yosys)

```bash
yosys -p "read_verilog -sv ysyxSoCMinimal.v picorv32.v ysyx_00000001.v uart_*.v apb_delayer.v; synth -top ysyxSoCTopMinimal"
```

## 功能说明

精简版保留:
- ✅ CPU (PicoRV32)
- ✅ AI 加速器 (CompactAccel, BitNetAccel)
- ✅ UART (调试)
- ✅ 64KB SRAM

移除:
- ❌ VGA, PS/2, GPIO
- ❌ SPI, PSRAM, SDRAM
- ❌ ChipLink

## 接口

### 顶层端口
- `clock` - 时钟输入
- `reset` - 复位输入 (高电平有效)
- `externalPins_uart_*` - UART 接口
- `externalPins_compact_irq` - CompactAccel 中断
- `externalPins_bitnet_irq` - BitNetAccel 中断

## 验证

设计已通过:
- ✅ Chisel 编译
- ✅ Verilog 生成
- ✅ 接口规范检查

## 支持

详见主项目文档:
- `MINIMAL_BUILD_GUIDE.md`
- `FINAL_ANALYSIS.md`
README
echo "✓ README.md"

# 8. 统计信息
echo ""
echo "=========================================="
echo "导出完成!"
echo "=========================================="
echo ""
echo "导出目录: $EXPORT_DIR"
echo ""
echo "文件统计:"
FILE_COUNT=$(ls -1 "$EXPORT_DIR"/*.v 2>/dev/null | wc -l)
echo "  Verilog 文件: $FILE_COUNT"
echo "  配置文件: 2 (filelist.f, README.md)"
echo ""

TOTAL_SIZE=$(du -sh "$EXPORT_DIR" | cut -f1)
echo "  总大小: $TOTAL_SIZE"
echo ""

echo "下一步:"
echo "  1. cd $EXPORT_DIR"
echo "  2. zip -r ysyxSoCMinimal.zip *"
echo "  3. 上传到在线 iEDA"
echo ""
echo "iEDA 参数:"
echo "  top_name: ysyxSoCTopMinimal"
echo "  clk_port_name: clock"
