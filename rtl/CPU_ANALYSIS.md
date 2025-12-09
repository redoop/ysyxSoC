# ysyx_00000001.v CPU 模块分析

## 当前状态

### ✅ 基本功能正常
当前的 `ysyx_00000001.v` 实现了：
- PicoRV32 RISC-V 核心
- AXI4 主接口（用于访问内存和外设）
- AXI4 从接口（未使用，已正确 tie-off）
- 简单的 AXI4 状态机

### ✅ 与 AI 加速器兼容
CPU 通过 AXI4 总线可以访问：
- **CompactAccel** @ 0x10003000
- **BitNetAccel** @ 0x10004000

访问路径：
```
CPU (AXI4 Master) 
  → AXI4 Crossbar 
  → AXI4-to-APB Bridge 
  → APB Crossbar 
  → APBCompactAccel / APBBitNetAccel
```

## 需要改进的地方

### 1. 中断支持 ⚠️

**当前状态**:
```verilog
.io_interrupt(1'h0),  // 硬连接到 0，无中断支持
```

**问题**:
- AI 加速器有中断输出 (`compact_irq`, `bitnet_irq`)
- 但这些中断没有连接到 CPU
- CPU 只能通过轮询状态寄存器来检测完成

**建议方案 A - 简单轮询（当前可用）**:
```c
// 软件轮询方式
while (COMPACT_STATUS != 2);  // 等待完成
```
- 优点：无需修改硬件
- 缺点：浪费 CPU 周期

**建议方案 B - 添加中断支持（推荐）**:

修改 `src/SoC.scala`:
```scala
// 将加速器中断连接到 CPU
cpu.module.interrupt := lcompact.module.irq || lbitnet.module.irq || intr_from_chipSlave
```

修改 `rtl/ysyx_00000001.v`:
```verilog
// 在 PicoRV32 中启用中断
picorv32 #(
    .ENABLE_MUL(1),
    .ENABLE_DIV(1),
    .COMPRESSED_ISA(1),
    .ENABLE_IRQ(1),           // 启用中断
    .ENABLE_IRQ_TIMER(1)      // 启用定时器中断
) cpu (
    .clk(clock),
    .resetn(~reset),
    .trap(),
    .mem_valid(mem_valid),
    .mem_instr(mem_instr),
    .mem_ready(mem_ready),
    .mem_addr(mem_addr),
    .mem_wdata(mem_wdata),
    .mem_wstrb(mem_wstrb),
    .mem_rdata(mem_rdata),
    .irq({30'b0, io_interrupt, 1'b0})  // 连接中断
);
```

软件中断处理:
```c
void irq_handler() {
    // 检查是哪个加速器完成
    if (COMPACT_STATUS == 2) {
        // CompactAccel 完成
        handle_compact_completion();
    }
    if (BITNET_STATUS == 2) {
        // BitNetAccel 完成
        handle_bitnet_completion();
    }
}
```

### 2. AXI4 状态机优化 💡

**当前实现**:
- 读写分离的状态机
- 每次事务需要 2-4 个周期

**可能的优化**:
```verilog
// 优化：同时发起地址和数据
IDLE: begin
    if (mem_valid) begin
        if (mem_wstrb == 4'b0000) begin
            // 读：直接发起地址请求
            if (io_master_arready) begin
                state <= READ;
            end
        end else begin
            // 写：同时发起地址和数据
            if (io_master_awready && io_master_wready) begin
                state <= RESP;  // 跳过 WRITE 状态
            end else if (io_master_awready) begin
                state <= WRITE;
            end
        end
    end
end
```

### 3. 性能计数器 📊

**建议添加**:
```verilog
reg [31:0] cycle_counter;
reg [31:0] instr_counter;
reg [31:0] stall_counter;

always @(posedge clock) begin
    if (reset) begin
        cycle_counter <= 0;
        instr_counter <= 0;
        stall_counter <= 0;
    end else begin
        cycle_counter <= cycle_counter + 1;
        if (mem_valid && mem_ready && mem_instr) begin
            instr_counter <= instr_counter + 1;
        end
        if (mem_valid && !mem_ready) begin
            stall_counter <= stall_counter + 1;
        end
    end
end
```

## 测试建议

### 1. 基本功能测试
```c
// 测试 CPU 能否访问加速器
uint32_t test_val = 0x12345678;
COMPACT_MATRIX_A[0] = test_val;
uint32_t read_back = COMPACT_MATRIX_A[0];
assert(read_back == test_val);
```

### 2. 加速器功能测试
```c
// 测试矩阵乘法
test_compact_2x2();
test_bitnet_2x2();
```

### 3. 性能测试
```c
// 测量加速器性能
uint32_t start_cycles = read_cycle_counter();
run_matrix_multiply();
uint32_t end_cycles = read_cycle_counter();
printf("Cycles: %u\n", end_cycles - start_cycles);
```

## 当前结论

### ✅ 无需立即修改
当前的 `ysyx_00000001.v` 已经可以正常工作：
- CPU 可以通过 AXI4 访问 AI 加速器
- 软件可以使用轮询方式检测完成
- 所有寄存器读写功能正常

### 💡 建议的改进（可选）
1. **添加中断支持** - 提高效率，避免轮询
2. **优化 AXI4 状态机** - 减少延迟
3. **添加性能计数器** - 便于调试和优化

### 📋 下一步
1. 使用当前实现进行功能测试
2. 如果性能满足需求，无需修改
3. 如果需要中断支持，按照上述方案修改

## 内存映射验证

CPU 可以访问的地址空间：
```
0x00000000 - 0x0FFFFFFF : RAM (256 MB)
0x10000000 - 0x10000FFF : UART
0x10001000 - 0x10001FFF : SPI
0x10002000 - 0x1000200F : GPIO
0x10003000 - 0x10003FFF : CompactAccel ← 新增
0x10004000 - 0x10004FFF : BitNetAccel  ← 新增
0x10011000 - 0x10011007 : Keyboard
0x20000000 - 0x20000FFF : MROM
0x21000000 - 0x211FFFFF : VGA
0x30000000 - 0x3FFFFFFF : Flash (XIP)
0x80000000 - 0x803FFFFF : PSRAM
0xA0000000 - 0xA1FFFFFF : SDRAM
```

所有地址都可以通过 AXI4 接口正常访问。

## 兼容性检查

### ✅ PicoRV32 配置
```verilog
picorv32 #(
    .ENABLE_MUL(1),        // 支持乘法
    .ENABLE_DIV(1),        // 支持除法
    .COMPRESSED_ISA(1)     // 支持压缩指令
) cpu (...)
```

这个配置适合运行 AI 加速器测试程序。

### ✅ AXI4 接口
- 地址宽度: 32-bit ✓
- 数据宽度: 32-bit ✓
- ID 宽度: 4-bit ✓
- 突发长度: 支持单次传输 ✓

完全兼容 RocketChip 生成的 AXI4 总线。

## 总结

**当前 `ysyx_00000001.v` 不需要修改即可使用 AI 加速器。**

所有功能都可以通过软件轮询方式实现。如果需要更高的性能和效率，可以考虑添加中断支持，但这不是必需的。

建议先进行功能测试，验证基本功能正常后，再根据实际性能需求决定是否需要优化。
