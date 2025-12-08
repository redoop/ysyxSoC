// test_accelerators.c - Test program for AI accelerators
// Compile and run on ysyxSoC to test the integrated accelerators

#include <stdint.h>
#include <stdio.h>

// CompactAccel registers
#define COMPACT_BASE 0x10003000
#define COMPACT_CTRL     (*(volatile uint32_t*)(COMPACT_BASE + 0x000))
#define COMPACT_STATUS   (*(volatile uint32_t*)(COMPACT_BASE + 0x004))
#define COMPACT_SIZE     (*(volatile uint32_t*)(COMPACT_BASE + 0x01C))
#define COMPACT_CYCLES   (*(volatile uint32_t*)(COMPACT_BASE + 0x028))
#define COMPACT_MATRIX_A ((volatile uint32_t*)(COMPACT_BASE + 0x100))
#define COMPACT_MATRIX_B ((volatile uint32_t*)(COMPACT_BASE + 0x300))
#define COMPACT_MATRIX_C ((volatile uint32_t*)(COMPACT_BASE + 0x500))

// BitNetAccel registers
#define BITNET_BASE 0x10004000
#define BITNET_CTRL     (*(volatile uint32_t*)(BITNET_BASE + 0x000))
#define BITNET_STATUS   (*(volatile uint32_t*)(BITNET_BASE + 0x004))
#define BITNET_SIZE     (*(volatile uint32_t*)(BITNET_BASE + 0x01C))
#define BITNET_CYCLES   (*(volatile uint32_t*)(BITNET_BASE + 0x028))
#define BITNET_SKIPPED  (*(volatile uint32_t*)(BITNET_BASE + 0x02C))
#define BITNET_ERROR    (*(volatile uint32_t*)(BITNET_BASE + 0x030))
#define BITNET_ACTIVATION ((volatile int32_t*)(BITNET_BASE + 0x100))
#define BITNET_WEIGHT     ((volatile int32_t*)(BITNET_BASE + 0x300))
#define BITNET_RESULT     ((volatile int32_t*)(BITNET_BASE + 0x500))

// Test CompactAccel with 4x4 identity matrix multiplication
void test_compact_identity() {
    printf("Testing CompactAccel with 4x4 identity matrix...\n");
    
    // Set matrix size
    COMPACT_SIZE = 4;
    
    // Initialize matrix A (sequential values)
    for (int i = 0; i < 16; i++) {
        COMPACT_MATRIX_A[i] = i + 1;
    }
    
    // Initialize matrix B (identity matrix)
    for (int i = 0; i < 16; i++) {
        COMPACT_MATRIX_B[i] = (i % 5 == 0) ? 1 : 0;
    }
    
    // Start computation
    COMPACT_CTRL = 1;
    
    // Wait for completion
    while (COMPACT_STATUS != 2);
    
    // Read and verify results
    printf("Results (should match input A):\n");
    int pass = 1;
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            uint32_t result = COMPACT_MATRIX_C[i * 8 + j];
            uint32_t expected = i * 4 + j + 1;
            printf("%4u ", result);
            if (result != expected) {
                pass = 0;
            }
        }
        printf("\n");
    }
    
    uint32_t cycles = COMPACT_CYCLES;
    printf("Cycles: %u\n", cycles);
    printf("Test %s\n\n", pass ? "PASSED" : "FAILED");
}

// Test BitNetAccel with simple ternary weights
void test_bitnet_simple() {
    printf("Testing BitNetAccel with 4x4 ternary weights...\n");
    
    // Set matrix size
    BITNET_SIZE = 4;
    
    // Initialize activation values
    for (int i = 0; i < 16; i++) {
        BITNET_ACTIVATION[i] = i + 1;
    }
    
    // Initialize BitNet weights (ternary: -1, 0, +1)
    int32_t weights[16] = {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    };
    for (int i = 0; i < 16; i++) {
        BITNET_WEIGHT[i] = weights[i];
    }
    
    // Start computation
    BITNET_CTRL = 1;
    
    // Wait for completion
    while (BITNET_STATUS == 1);
    
    // Check for errors
    if (BITNET_STATUS == 3) {
        printf("Error: %u\n", BITNET_ERROR);
        return;
    }
    
    // Read and display results
    printf("Results (should match input activations):\n");
    int pass = 1;
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            int32_t result = BITNET_RESULT[i * 16 + j];
            int32_t expected = i * 4 + j + 1;
            printf("%4d ", result);
            if (result != expected) {
                pass = 0;
            }
        }
        printf("\n");
    }
    
    uint32_t cycles = BITNET_CYCLES;
    uint32_t skipped = BITNET_SKIPPED;
    printf("Cycles: %u, Skipped: %u\n", cycles, skipped);
    printf("Test %s\n\n", pass ? "PASSED" : "FAILED");
}

// Test BitNetAccel with sparse weights
void test_bitnet_sparse() {
    printf("Testing BitNetAccel with sparse weights...\n");
    
    // Set matrix size
    BITNET_SIZE = 4;
    
    // Initialize activation values
    for (int i = 0; i < 16; i++) {
        BITNET_ACTIVATION[i] = 1;
    }
    
    // Initialize sparse weights (mostly zeros)
    int32_t weights[16] = {
        1, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, -1, 0,
        0, 0, 0, 1
    };
    for (int i = 0; i < 16; i++) {
        BITNET_WEIGHT[i] = weights[i];
    }
    
    // Start computation
    BITNET_CTRL = 1;
    
    // Wait for completion
    while (BITNET_STATUS == 1);
    
    // Check for errors
    if (BITNET_STATUS == 3) {
        printf("Error: %u\n", BITNET_ERROR);
        return;
    }
    
    // Read and display results
    printf("Results:\n");
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            int32_t result = BITNET_RESULT[i * 16 + j];
            printf("%4d ", result);
        }
        printf("\n");
    }
    
    uint32_t cycles = BITNET_CYCLES;
    uint32_t skipped = BITNET_SKIPPED;
    printf("Cycles: %u, Skipped: %u (sparsity optimization)\n", cycles, skipped);
    printf("Expected high skip count due to sparse weights\n\n");
}

int main() {
    printf("=== AI Accelerator Test Suite ===\n\n");
    
    test_compact_identity();
    test_bitnet_simple();
    test_bitnet_sparse();
    
    printf("=== All tests completed ===\n");
    return 0;
}
