#!/usr/bin/env python3
import sys

with open(sys.argv[1], 'r') as f:
    lines = f.readlines()

output = []
i = 0
while i < len(lines):
    line = lines[i]
    
    # 检测断言块开始
    if 'if (~reset' in line:
        # 收集整个 if 条件（可能跨多行）
        block_start = i
        paren_count = line.count('(') - line.count(')')
        j = i + 1
        
        # 找到条件结束和 begin
        while j < len(lines) and ('begin' not in lines[j-1] or paren_count != 0):
            paren_count += lines[j].count('(') - lines[j].count(')')
            j += 1
        
        # 检查块内容是否是断言
        is_assertion = False
        k = j
        while k < len(lines) and k < j + 10:
            if '$error' in lines[k] or '$fatal' in lines[k]:
                is_assertion = True
                break
            if lines[k].strip() == 'end':
                break
            k += 1
        
        if is_assertion:
            # 跳过整个断言块
            while i < len(lines):
                if lines[i].strip() == 'end':
                    i += 1
                    break
                i += 1
            continue
    
    output.append(line)
    i += 1

with open(sys.argv[1], 'w') as f:
    f.writelines(output)

print(f"Assertions removed from {sys.argv[1]}")
