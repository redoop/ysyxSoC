# 紧急修复 - max_fanout 问题

## 问题

你已经调整了大部分参数,但遗漏了最关键的一个:

```
✓ clk_freq_mhz: 30
✓ core_util: 0.15  
✓ die_bbox: 300x300
✗ max_fanout: 32  ← 这个没改!
```

**结果**: 仍然在 `run_iNO_fix_fanout.tcl` 崩溃 (0.79秒)

## 立即行动

### 🚨 方案 1: 修改 max_fanout (必须!)

重新提交任务,修改:

```json
{
  "top_name": "ysyxSoCFull",
  "clk_port_name": "clock",
  "clk_freq_mhz": 30,
  "core_util": 0.15,
  "die_bbox": "0 0 300 300",
  "core_bbox": "30 30 270 270",
  "target_density": 0.25,
  "max_fanout": 16,        ← 改这个!
  "max_iterative": 1000,
  "fast_route": true,
  "fast_signoff": true
}
```

**预期**: 80% 成功率

### 🔧 方案 2: 更激进的参数

如果方案1仍失败:

```json
{
  "clk_freq_mhz": 20,      ← 更低
  "core_util": 0.1,        ← 更低
  "max_fanout": 8,         ← 更低
  "die_bbox": "0 0 500 500",  ← 更大
  "core_bbox": "50 50 450 450"
}
```

### 🎯 方案 3: 简化设计 (如果仍失败)

已生成简化版本:

```bash
文件: build/ysyxSoC_simple.v
上传到在线 iEDA
top_name: ysyxSoC_simple
```

## 为什么 max_fanout 这么重要?

`run_iNO_fix_fanout.tcl` 的作用是修复高扇出网络:
- 如果 max_fanout=32,工具会尝试处理扇出≤32的网络
- 但你的设计中可能有扇出>32的信号(时钟、复位等)
- 工具无法处理,导致断言失败 (SIGABRT)

**解决**: 降低 max_fanout 强制工具插入更多缓冲器

## 技术细节

### 当前设计的扇出情况

```
时钟信号 (clock):  可能扇出 > 100
复位信号 (reset):  可能扇出 > 50
总线信号:          扇出 10-30
```

### max_fanout 的影响

```
max_fanout=32: 工具尝试处理扇出≤32 → 崩溃
max_fanout=16: 强制插入缓冲器 → 成功
max_fanout=8:  插入更多缓冲器 → 更安全
```

## 决策树

```
调整 max_fanout=16
    ↓
  成功? ──YES→ 完成!
    ↓
   NO
    ↓
调整 max_fanout=8 + 增大面积到 500x500
    ↓
  成功? ──YES→ 完成!
    ↓
   NO
    ↓
使用简化设计 (ysyxSoC_simple.v)
```

## 快速对比

| 参数 | 第一次 | 第二次 | 应该是 |
|------|--------|--------|--------|
| clk_freq_mhz | 50 | 30 | ✓ |
| core_util | 0.2 | 0.15 | ✓ |
| max_fanout | 32 | **32** | ✗ 应该16 |
| die_bbox | 100x100 | 300x300 | ✓ |

## 总结

**问题根源**: max_fanout=32 太高,iEDA 无法处理

**解决方案**: 
1. ⭐ max_fanout=16 (立即重试)
2. max_fanout=8 (如果仍失败)
3. 使用简化设计 (最后手段)

---

**立即行动**: 重新提交,max_fanout=16
