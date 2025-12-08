# iEDA netlist optimization test script
# Test if iEDA can handle the synthesized netlist

puts "=========================================="
puts "Testing iEDA netlist optimization"
puts "=========================================="

# Set design name
set DESIGN "ysyxSoCFull"
set NETLIST "netlist/${DESIGN}_ics55.v"

# Check if netlist exists
if {![file exists $NETLIST]} {
    puts "ERROR: Netlist not found: $NETLIST"
    exit 1
}

puts "Netlist: $NETLIST"
puts "Size: [file size $NETLIST] bytes"

# Read Liberty files
set LIB_DIR "/opt/github/riscv-ai-accelerator/chisel/synthesis/pdk/icsprout55-pdk/IP/STD_cell/ics55_LLSC_H7C_V1p10C100"
set LIB_L "${LIB_DIR}/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"

if {[file exists $LIB_L]} {
    puts "Reading Liberty: $LIB_L"
    read_liberty $LIB_L
} else {
    puts "WARNING: Liberty file not found: $LIB_L"
}

# Read netlist
puts "\nReading netlist..."
read_verilog $NETLIST

# Link design
puts "\nLinking design..."
link_design $DESIGN

# Report design statistics
puts "\n=========================================="
puts "Design Statistics"
puts "=========================================="
report_design_area

puts "\nTest completed successfully!"
