#!/bin/bash
# Analyze synthesized netlist

NETLIST="netlist/ysyxSoCFull_ics55.v"
STATS="netlist/synthesis_stats_ics55.txt"

echo "=========================================="
echo "Netlist Analysis"
echo "=========================================="

if [ ! -f "$NETLIST" ]; then
    echo "ERROR: Netlist not found: $NETLIST"
    exit 1
fi

echo "File: $NETLIST"
echo "Size: $(du -h $NETLIST | cut -f1)"
echo "Lines: $(wc -l < $NETLIST)"
echo ""

echo "Cell Count:"
grep -E "^\s*\w+X\w+H7[LC]\s" "$NETLIST" | wc -l

echo ""
echo "Module Count:"
grep "^module" "$NETLIST" | wc -l

echo ""
echo "Top 10 Most Used Cells:"
grep -oE "\w+X\w+H7[LC]" "$NETLIST" | sort | uniq -c | sort -rn | head -10

if [ -f "$STATS" ]; then
    echo ""
    echo "=========================================="
    echo "Synthesis Statistics"
    echo "=========================================="
    grep -A 5 "Chip area for top" "$STATS" | head -6
fi

echo ""
echo "=========================================="
echo "Analysis Complete"
echo "=========================================="
