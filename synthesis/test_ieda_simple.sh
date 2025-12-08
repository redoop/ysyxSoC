#!/bin/bash
# Simple test to check if iEDA can be invoked

echo "=========================================="
echo "Testing iEDA availability"
echo "=========================================="

# Check if iEDA is available
if command -v iEDA &> /dev/null; then
    echo "✓ iEDA found: $(which iEDA)"
    iEDA -version 2>&1 || echo "iEDA version check failed"
else
    echo "✗ iEDA not found in PATH"
    echo ""
    echo "Searching for iEDA..."
    find /opt /home -name "iEDA" -type f 2>/dev/null | head -5
fi

echo ""
echo "Design Statistics:"
echo "  Total cells: 202,574"
echo "  Total area: 800,914.52 µm²"
echo "  Sequential: 53.87%"
echo "  Netlist size: 24MB (1.3M lines)"
echo ""
echo "Recommendation:"
echo "  This is a large design. Consider:"
echo "  1. Die size: at least 3000x3000 µm"
echo "  2. Core utilization: 0.3-0.4"
echo "  3. Enable hierarchy preservation"
