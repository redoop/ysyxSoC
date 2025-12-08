# 在线 EDA 配置建议

## 设计规模分析

- **单元数量**: 202,574 个
- **芯片面积**: 800,914.52 µm²
- **时序单元**: 53.87% (68,983 个触发器)
- **网表大小**: 24MB (1,335,618 行)

## 问题原因

当前配置的芯片尺寸太小：
```
DIE_BBOX: "0 0 100 100"      # 仅 100x100 µm
CORE_BBOX: "10 10 90 90"      # 核心区域 80x80 µm
```

对于 80万 µm² 的设计，这个尺寸完全不够。

## 推荐配置

### 方案1：标准配置（推荐）

```yaml
top_name: "ysyxSoCFull"
clk_port_name: "clock"
clk_freq_mhz: 50
core_util: 0.35
die_bbox: "0 0 3000 3000"      # 3mm x 3mm
core_bbox: "100 100 2900 2900"  # 核心区域
target_density: 0.4
max_fanout: 64
```

**预计芯片面积**: 约 2.3 mm² (800,914 µm² / 0.35)

### 方案2：保守配置（更安全）

```yaml
core_util: 0.25
die_bbox: "0 0 4000 4000"      # 4mm x 4mm
core_bbox: "100 100 3900 3900"
target_density: 0.35
```

**预计芯片面积**: 约 3.2 mm²

### 方案3：紧凑配置（激进）

```yaml
core_util: 0.50
die_bbox: "0 0 2000 2000"      # 2mm x 2mm
core_bbox: "100 100 1900 1900"
target_density: 0.5
```

**预计芯片面积**: 约 1.6 mm² (可能布线困难)

## 其他建议

1. **启用层次保持** (如果工具支持):
   ```yaml
   keep_hierarchy: true
   ```

2. **增加迭代次数**:
   ```yaml
   max_iterative: 5000
   ```

3. **放宽时序约束** (初次尝试):
   ```yaml
   clk_freq_mhz: 25  # 降低到 25MHz
   ```

4. **分阶段验证**:
   - 先完成 floorplan
   - 再进行 placement
   - 最后 routing

## 计算公式

```
所需核心面积 = 单元总面积 / 利用率
            = 800,914.52 µm² / 0.35
            = 2,288,327 µm²
            ≈ 1513 x 1513 µm

建议芯片尺寸 = √(所需核心面积 * 1.5)  # 留余量
            ≈ 1850 x 1850 µm
            
保守估计: 3000 x 3000 µm (9 mm²)
```

## 上传前检查清单

- [x] 网表已生成: `ysyxSoCFull_ics55.v`
- [x] 网表已验证: Icarus Verilog 仿真通过
- [x] 文件已导出: `rtl_export/` 目录
- [ ] 芯片尺寸已调整: 至少 3000x3000
- [ ] 利用率已调整: 0.3-0.4
- [ ] 时钟频率合理: 25-50 MHz

## 预期结果

使用推荐配置后：
- ✓ netlist_opt 应该能正常完成
- ✓ floorplan 会生成合理的布局
- ✓ placement 可以放置所有单元
- ✓ routing 有足够空间布线
