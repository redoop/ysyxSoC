#!/bin/bash
# 修复 Chisel 生成的 AXI 信号命名

FILE="build/ysyxSoCMinimal.v"

if [ ! -f "$FILE" ]; then
    echo "错误: $FILE 不存在"
    exit 1
fi

echo "修复 AXI 信号命名..."

# 备份
cp "$FILE" "${FILE}.bak"

# 修复信号名称 (Chisel 格式 -> ysyx 格式)
sed -i 's/io_master_aw_ready/io_master_awready/g' "$FILE"
sed -i 's/io_master_aw_valid/io_master_awvalid/g' "$FILE"
sed -i 's/io_master_aw_bits_id/io_master_awid/g' "$FILE"
sed -i 's/io_master_aw_bits_addr/io_master_awaddr/g' "$FILE"
sed -i 's/io_master_aw_bits_len/io_master_awlen/g' "$FILE"
sed -i 's/io_master_aw_bits_size/io_master_awsize/g' "$FILE"
sed -i 's/io_master_aw_bits_burst/io_master_awburst/g' "$FILE"
sed -i 's/io_master_aw_bits_lock/io_master_awlock/g' "$FILE"
sed -i 's/io_master_aw_bits_cache/io_master_awcache/g' "$FILE"
sed -i 's/io_master_aw_bits_prot/io_master_awprot/g' "$FILE"
sed -i 's/io_master_aw_bits_qos/io_master_awqos/g' "$FILE"

sed -i 's/io_master_w_ready/io_master_wready/g' "$FILE"
sed -i 's/io_master_w_valid/io_master_wvalid/g' "$FILE"
sed -i 's/io_master_w_bits_data/io_master_wdata/g' "$FILE"
sed -i 's/io_master_w_bits_strb/io_master_wstrb/g' "$FILE"
sed -i 's/io_master_w_bits_last/io_master_wlast/g' "$FILE"

sed -i 's/io_master_b_ready/io_master_bready/g' "$FILE"
sed -i 's/io_master_b_valid/io_master_bvalid/g' "$FILE"
sed -i 's/io_master_b_bits_id/io_master_bid/g' "$FILE"
sed -i 's/io_master_b_bits_resp/io_master_bresp/g' "$FILE"

sed -i 's/io_master_ar_ready/io_master_arready/g' "$FILE"
sed -i 's/io_master_ar_valid/io_master_arvalid/g' "$FILE"
sed -i 's/io_master_ar_bits_id/io_master_arid/g' "$FILE"
sed -i 's/io_master_ar_bits_addr/io_master_araddr/g' "$FILE"
sed -i 's/io_master_ar_bits_len/io_master_arlen/g' "$FILE"
sed -i 's/io_master_ar_bits_size/io_master_arsize/g' "$FILE"
sed -i 's/io_master_ar_bits_burst/io_master_arburst/g' "$FILE"
sed -i 's/io_master_ar_bits_lock/io_master_arlock/g' "$FILE"
sed -i 's/io_master_ar_bits_cache/io_master_arcache/g' "$FILE"
sed -i 's/io_master_ar_bits_prot/io_master_arprot/g' "$FILE"
sed -i 's/io_master_ar_bits_qos/io_master_arqos/g' "$FILE"

sed -i 's/io_master_r_ready/io_master_rready/g' "$FILE"
sed -i 's/io_master_r_valid/io_master_rvalid/g' "$FILE"
sed -i 's/io_master_r_bits_id/io_master_rid/g' "$FILE"
sed -i 's/io_master_r_bits_data/io_master_rdata/g' "$FILE"
sed -i 's/io_master_r_bits_resp/io_master_rresp/g' "$FILE"
sed -i 's/io_master_r_bits_last/io_master_rlast/g' "$FILE"

# Slave 接口
sed -i 's/io_slave_aw_ready/io_slave_awready/g' "$FILE"
sed -i 's/io_slave_aw_valid/io_slave_awvalid/g' "$FILE"
sed -i 's/io_slave_aw_bits_id/io_slave_awid/g' "$FILE"
sed -i 's/io_slave_aw_bits_addr/io_slave_awaddr/g' "$FILE"
sed -i 's/io_slave_aw_bits_len/io_slave_awlen/g' "$FILE"
sed -i 's/io_slave_aw_bits_size/io_slave_awsize/g' "$FILE"
sed -i 's/io_slave_aw_bits_burst/io_slave_awburst/g' "$FILE"
sed -i 's/io_slave_aw_bits_lock/io_slave_awlock/g' "$FILE"
sed -i 's/io_slave_aw_bits_cache/io_slave_awcache/g' "$FILE"
sed -i 's/io_slave_aw_bits_prot/io_slave_awprot/g' "$FILE"
sed -i 's/io_slave_aw_bits_qos/io_slave_awqos/g' "$FILE"

sed -i 's/io_slave_w_ready/io_slave_wready/g' "$FILE"
sed -i 's/io_slave_w_valid/io_slave_wvalid/g' "$FILE"
sed -i 's/io_slave_w_bits_data/io_slave_wdata/g' "$FILE"
sed -i 's/io_slave_w_bits_strb/io_slave_wstrb/g' "$FILE"
sed -i 's/io_slave_w_bits_last/io_slave_wlast/g' "$FILE"

sed -i 's/io_slave_b_ready/io_slave_bready/g' "$FILE"
sed -i 's/io_slave_b_valid/io_slave_bvalid/g' "$FILE"
sed -i 's/io_slave_b_bits_id/io_slave_bid/g' "$FILE"
sed -i 's/io_slave_b_bits_resp/io_slave_bresp/g' "$FILE"

sed -i 's/io_slave_ar_ready/io_slave_arready/g' "$FILE"
sed -i 's/io_slave_ar_valid/io_slave_arvalid/g' "$FILE"
sed -i 's/io_slave_ar_bits_id/io_slave_arid/g' "$FILE"
sed -i 's/io_slave_ar_bits_addr/io_slave_araddr/g' "$FILE"
sed -i 's/io_slave_ar_bits_len/io_slave_arlen/g' "$FILE"
sed -i 's/io_slave_ar_bits_size/io_slave_arsize/g' "$FILE"
sed -i 's/io_slave_ar_bits_burst/io_slave_arburst/g' "$FILE"
sed -i 's/io_slave_ar_bits_lock/io_slave_arlock/g' "$FILE"
sed -i 's/io_slave_ar_bits_cache/io_slave_arcache/g' "$FILE"
sed -i 's/io_slave_ar_bits_prot/io_slave_arprot/g' "$FILE"
sed -i 's/io_slave_ar_bits_qos/io_slave_arqos/g' "$FILE"

sed -i 's/io_slave_r_ready/io_slave_rready/g' "$FILE"
sed -i 's/io_slave_r_valid/io_slave_rvalid/g' "$FILE"
sed -i 's/io_slave_r_bits_id/io_slave_rid/g' "$FILE"
sed -i 's/io_slave_r_bits_data/io_slave_rdata/g' "$FILE"
sed -i 's/io_slave_r_bits_resp/io_slave_rresp/g' "$FILE"
sed -i 's/io_slave_r_bits_last/io_slave_rlast/g' "$FILE"

echo "✓ 信号名称已修复"
echo "✓ 备份文件: ${FILE}.bak"
