#!/bin/bash
# 删除包含 $error 和 $fatal 的行
sed -i '/\$error\|^\s*\$fatal/d' "$1"
# 删除空的断言 if 块
sed -i '/if (~reset &.*) begin$/,/^      end$/{
  /if (`ASSERT_VERBOSE_COND_`)/d
  /if (`STOP_COND_`)/d
  /if (~reset &.*) begin$/d
  /^      end$/d
}' "$1"
echo "Assertions removed from $1"
