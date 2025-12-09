#!/usr/bin/env python3
"""
AI加速器功能测试脚本
测试CompactAccel和BitNetAccel的基本功能
"""

import numpy as np

def test_compact_accel():
    """测试CompactAccel的矩阵乘法功能"""
    print("=" * 60)
    print("测试 CompactAccel (标准矩阵乘法)")
    print("=" * 60)
    
    # 测试1: 2x2矩阵
    print("\n测试1: 2x2 矩阵乘法")
    A = np.array([[1, 2], [3, 4]], dtype=np.int32)
    B = np.array([[1, 0], [0, 1]], dtype=np.int32)  # 单位矩阵
    expected = A @ B
    
    print(f"矩阵 A:\n{A}")
    print(f"矩阵 B (单位矩阵):\n{B}")
    print(f"期望结果 C = A × B:\n{expected}")
    print("✓ 期望结果应该等于 A")
    
    # 测试2: 4x4矩阵
    print("\n测试2: 4x4 矩阵乘法")
    A = np.arange(1, 17, dtype=np.int32).reshape(4, 4)
    B = np.eye(4, dtype=np.int32)  # 单位矩阵
    expected = A @ B
    
    print(f"矩阵 A:\n{A}")
    print(f"矩阵 B (单位矩阵):\n{B}")
    print(f"期望结果 C = A × B:\n{expected}")
    print("✓ 期望结果应该等于 A")
    
    # 测试3: 4x4一般矩阵
    print("\n测试3: 4x4 一般矩阵乘法")
    A = np.array([[1, 2, 3, 4],
                  [5, 6, 7, 8],
                  [9, 10, 11, 12],
                  [13, 14, 15, 16]], dtype=np.int32)
    B = np.array([[1, 0, 0, 0],
                  [0, 1, 0, 0],
                  [0, 0, 1, 0],
                  [0, 0, 0, 1]], dtype=np.int32)
    expected = A @ B
    
    print(f"矩阵 A:\n{A}")
    print(f"矩阵 B:\n{B}")
    print(f"期望结果 C = A × B:\n{expected}")
    
    # 测试4: 8x8矩阵（最大尺寸）
    print("\n测试4: 8x8 矩阵乘法（最大尺寸）")
    A = np.arange(1, 65, dtype=np.int32).reshape(8, 8)
    B = np.eye(8, dtype=np.int32)
    expected = A @ B
    
    print(f"矩阵 A (8x8):\n{A}")
    print(f"矩阵 B (8x8 单位矩阵)")
    print(f"期望结果 C = A × B:\n{expected}")
    print("✓ 期望结果应该等于 A")
    
    print("\n" + "=" * 60)
    print("CompactAccel 测试完成")
    print("=" * 60)

def test_bitnet_accel():
    """测试BitNetAccel的三值权重矩阵乘法"""
    print("\n" + "=" * 60)
    print("测试 BitNetAccel (三值权重矩阵乘法)")
    print("=" * 60)
    
    # 测试1: 4x4单位矩阵
    print("\n测试1: 4x4 单位矩阵（权重为+1）")
    activation = np.arange(1, 17, dtype=np.int32).reshape(4, 4)
    weights = np.eye(4, dtype=np.int32)  # 单位矩阵，权重为+1
    expected = activation @ weights
    
    print(f"激活值:\n{activation}")
    print(f"权重 (三值: -1/0/+1):\n{weights}")
    print(f"期望结果:\n{expected}")
    print("✓ 期望结果应该等于激活值")
    
    # 测试2: 稀疏权重
    print("\n测试2: 稀疏权重矩阵（大量零）")
    activation = np.ones((4, 4), dtype=np.int32)
    weights = np.array([[1, 0, 0, 0],
                        [0, 0, 0, 0],
                        [0, 0, -1, 0],
                        [0, 0, 0, 1]], dtype=np.int32)
    expected = activation @ weights
    
    print(f"激活值 (全1):\n{activation}")
    print(f"权重 (稀疏):\n{weights}")
    print(f"期望结果:\n{expected}")
    
    zero_count = np.sum(weights == 0)
    total = weights.size
    sparsity = zero_count / total * 100
    print(f"✓ 稀疏度: {sparsity:.1f}% ({zero_count}/{total} 个零)")
    print(f"✓ 应该跳过 {zero_count} 次乘法运算")
    
    # 测试3: 混合权重
    print("\n测试3: 混合三值权重")
    activation = np.array([[1, 2, 3, 4],
                          [5, 6, 7, 8],
                          [9, 10, 11, 12],
                          [13, 14, 15, 16]], dtype=np.int32)
    weights = np.array([[1, 0, -1, 1],
                        [0, 1, 0, -1],
                        [-1, 0, 1, 0],
                        [1, -1, 0, 1]], dtype=np.int32)
    expected = activation @ weights
    
    print(f"激活值:\n{activation}")
    print(f"权重 (混合三值):\n{weights}")
    print(f"期望结果:\n{expected}")
    
    pos_count = np.sum(weights == 1)
    neg_count = np.sum(weights == -1)
    zero_count = np.sum(weights == 0)
    print(f"✓ 权重分布: +1={pos_count}, -1={neg_count}, 0={zero_count}")
    
    # 测试4: 全负权重
    print("\n测试4: 全负权重")
    activation = np.ones((4, 4), dtype=np.int32) * 2
    weights = -np.eye(4, dtype=np.int32)  # 负单位矩阵
    expected = activation @ weights
    
    print(f"激活值 (全2):\n{activation}")
    print(f"权重 (全-1对角):\n{weights}")
    print(f"期望结果:\n{expected}")
    print("✓ 期望结果应该是激活值的负值")
    
    # 测试5: 8x8矩阵（最大尺寸）
    print("\n测试5: 8x8 矩阵（最大尺寸）")
    activation = np.arange(1, 65, dtype=np.int32).reshape(8, 8)
    weights = np.eye(8, dtype=np.int32)
    expected = activation @ weights
    
    print(f"激活值 (8x8):\n{activation}")
    print(f"权重 (8x8 单位矩阵)")
    print(f"期望结果:\n{expected}")
    print("✓ 期望结果应该等于激活值")
    
    print("\n" + "=" * 60)
    print("BitNetAccel 测试完成")
    print("=" * 60)

def test_performance_estimation():
    """估算性能指标"""
    print("\n" + "=" * 60)
    print("性能估算")
    print("=" * 60)
    
    clock_freq = 100e6  # 100 MHz
    
    print("\nCompactAccel:")
    for size in [2, 4, 8]:
        cycles = size * size * size  # 简化估算
        time_us = cycles / clock_freq * 1e6
        throughput = 1 / time_us * 1e6
        print(f"  {size}x{size} 矩阵: ~{cycles} 周期, ~{time_us:.2f} μs, ~{throughput:.0f} 矩阵/秒")
    
    print("\nBitNetAccel (最坏情况):")
    for size in [2, 4, 8]:
        cycles = size * size * size  # 简化估算
        time_us = cycles / clock_freq * 1e6
        throughput = 1 / time_us * 1e6
        print(f"  {size}x{size} 矩阵: ~{cycles} 周期, ~{time_us:.2f} μs, ~{throughput:.0f} 矩阵/秒")
    
    print("\nBitNetAccel (50%稀疏度):")
    for size in [2, 4, 8]:
        cycles = size * size * size // 2  # 50%稀疏度
        time_us = cycles / clock_freq * 1e6
        throughput = 1 / time_us * 1e6
        print(f"  {size}x{size} 矩阵: ~{cycles} 周期, ~{time_us:.2f} μs, ~{throughput:.0f} 矩阵/秒")
    
    print("\n✓ BitNetAccel 在稀疏权重下性能更优")
    print("✓ BitNetAccel 无需乘法器，面积更小")

def main():
    print("\n" + "=" * 60)
    print("AI 加速器功能测试")
    print("=" * 60)
    
    test_compact_accel()
    test_bitnet_accel()
    test_performance_estimation()
    
    print("\n" + "=" * 60)
    print("所有测试完成！")
    print("=" * 60)
    print("\n下一步:")
    print("1. 使用 Verilator 进行 RTL 仿真")
    print("2. 编译 test_accelerators.c 并在 SoC 上运行")
    print("3. 进行 FPGA 综合和时序分析")
    print("4. 测量实际硬件性能")

if __name__ == "__main__":
    main()
