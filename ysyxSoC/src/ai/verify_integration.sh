#!/bin/bash
# verify_integration.sh - Verify AI accelerator integration

echo "=== AI Accelerator Integration Verification ==="
echo ""

# Check if all required files exist
echo "Checking files..."
files=(
    "SimpleRegIO.scala"
    "SimpleMemoryMap.scala"
    "SimpleCompactAccel.scala"
    "SimpleBitNetAccel.scala"
    "APBAccelerators.scala"
    "AXI4ToSimpleReg.scala"
    "README.md"
    "INTEGRATION.md"
    "QUICKSTART.md"
    "test_accelerators.c"
)

all_exist=true
for file in "${files[@]}"; do
    if [ -f "src/ai/$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (MISSING)"
        all_exist=false
    fi
done

echo ""

# Check if SoC.scala has been modified
echo "Checking SoC integration..."
if grep -q "lcompact" src/SoC.scala && grep -q "lbitnet" src/SoC.scala; then
    echo "  ✓ Accelerators added to SoC.scala"
else
    echo "  ✗ Accelerators NOT found in SoC.scala"
    all_exist=false
fi

if grep -q "APBCompactAccel" src/SoC.scala && grep -q "APBBitNetAccel" src/SoC.scala; then
    echo "  ✓ APB wrappers instantiated"
else
    echo "  ✗ APB wrappers NOT instantiated"
    all_exist=false
fi

if grep -q "compact_irq" src/SoC.scala && grep -q "bitnet_irq" src/SoC.scala; then
    echo "  ✓ Interrupt signals exposed"
else
    echo "  ✗ Interrupt signals NOT exposed"
    all_exist=false
fi

echo ""

# Check memory map
echo "Checking memory map..."
if grep -q "0x10003000" src/SoC.scala; then
    echo "  ✓ CompactAccel mapped to 0x10003000"
else
    echo "  ✗ CompactAccel address NOT found"
    all_exist=false
fi

if grep -q "0x10004000" src/SoC.scala; then
    echo "  ✓ BitNetAccel mapped to 0x10004000"
else
    echo "  ✗ BitNetAccel address NOT found"
    all_exist=false
fi

echo ""

# Summary
if [ "$all_exist" = true ]; then
    echo "=== ✅ Integration verification PASSED ==="
    echo ""
    echo "Next steps:"
    echo "  1. Run 'make' to compile the SoC"
    echo "  2. Run simulation tests"
    echo "  3. Compile and run test_accelerators.c"
    echo ""
    echo "Documentation:"
    echo "  - Quick start: src/ai/QUICKSTART.md"
    echo "  - Full docs:   src/ai/README.md"
    echo "  - Integration: src/ai/INTEGRATION.md"
    exit 0
else
    echo "=== ❌ Integration verification FAILED ==="
    echo ""
    echo "Please check the missing files or configurations above."
    exit 1
fi
