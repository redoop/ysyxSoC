# ysyxSoCFull RTL Export (Reduced RAM Version)

完整的 RTL 源文件，RAM 已从 2048x32 (8KB) 减少到 512x32 (2KB)。

## 设计规模

| 项目 | 数值 |
|------|------|
| 总实例数 | 67,152 |
| 芯片面积 | 244,694 µm² |
| 触发器数量 | 19,829 |
| 网表大小 | 7.7MB (447K 行) |
| RAM 大小 | 2KB (512x32) |

## 文件说明

- `ysyxSoCFull.v` - 主设计文件 (Chisel 生成)
- `picorv32.v` - RISC-V CPU 核心
- `ysyx_00000001.v` - CPU 包装器 (AXI4 接口)
- `filelist.f` - 文件列表（按依赖顺序）
- 其他 `.v` 文件 - 外设模块

## 修复的文件

- `flash_fixed.v` - 修复了 enum 语法，移除了仿真专用构造
- `sdram_top_apb_fixed.v` - 修复了 enum 语法

## 使用方法

### Yosys 综合

```tcl
# 读取所有文件
read_slang -f filelist.f --top ysyxSoCFull
```

### 文件总数

30 个 Verilog 文件（包含 CPU RTL）

## 芯片尺寸建议

基于 244,694 µm² 的面积：

- **利用率 0.3**: 1000x1000 µm (1mm x 1mm)
- **利用率 0.4**: 900x900 µm
- **利用率 0.5**: 800x800 µm

推荐配置：
```yaml
die_bbox: "0 0 1200 1200"
core_bbox: "50 50 1150 1150"
core_util: 0.35
```

## 与原设计对比

| 项目 | 原设计 | 裁剪后 | 减少 |
|------|--------|--------|------|
| 实例数 | 202,574 | 67,152 | 66.9% |
| 面积 | 800,915 µm² | 244,694 µm² | 69.5% |
| RAM | 8KB | 2KB | 75% |
| 网表大小 | 24MB | 7.7MB | 67.9% |

## 注意事项

1. RAM 减少到 2KB，适合运行小型程序
2. 如需更多 RAM，可使用外部 SDRAM/PSRAM
3. 设计规模已满足 < 100,000 实例的要求
