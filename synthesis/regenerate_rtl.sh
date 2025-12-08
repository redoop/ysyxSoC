#!/bin/bash
# Regenerate RTL with reduced RAM size

echo "=========================================="
echo "Regenerating RTL with reduced RAM"
echo "=========================================="
echo ""
echo "Changes:"
echo "  - RAM size: 2048x32 (8KB) -> 512x32 (2KB)"
echo "  - Expected instances: ~50,000 (减少75%)"
echo ""

cd /opt/github/riscv-ai-accelerator/ecos/ysyxSoC

echo "Step 1: Clean previous build..."
make clean

echo ""
echo "Step 2: Generate new Verilog..."
make verilog

echo ""
echo "Step 3: Check generated file..."
if [ -f "build/ysyxSoCFull.v" ]; then
    echo "✓ Generated: build/ysyxSoCFull.v"
    grep -c "mem_512x32" build/ysyxSoCFull.v && echo "✓ RAM size updated to 512x32"
else
    echo "✗ Generation failed"
    exit 1
fi

echo ""
echo "Step 4: Copy to synthesis directory..."
cd synthesis
cp ../build/ysyxSoCFull.v rtl_export/

echo ""
echo "Step 5: Re-run synthesis..."
bash run_ics55_synthesis.sh

echo ""
echo "=========================================="
echo "Complete! Check netlist size:"
echo "  ./analyze_netlist.sh"
echo "=========================================="
