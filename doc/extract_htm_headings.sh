#!/bin/bash

: '
目的：提取示例html的标题
步骤：
    1、遍历目录下的所有htm文件（格式：数字-名称.htm）
    2、提取文件中的数字；按数字升序排列
        使用 sort -n  /// -n==numeric sort，即按照数字顺序进行排序）
    3、依次读取文件中的二级标题 
        使用 grep 命令提取 <h2> 标签里的文本，再用 sed 命令去掉 <h2> 和 </h2> 标签 
        sed是文本进行替换操作。 `s/查找/替换/` 没有替换就是删除呀 == s/xx//
    4、结果以 Markdown 超链接有序列表的格式输出（1. [标题](文件名)）
权限：
    chmod +x extract_htm_headings.sh
执行：
    ./extract_htm_headings.sh ../co
'

# 检查是否提供了目录参数： $#是命令行参数的数量
echo "参数数量：$#"

if [ $# -eq 0 ]; then
    echo "请提供一个目录作为参数。"
    exit 1
fi

# 要遍历的目录
target_dir="$1"

# 检查目录是否存在：  -d=directory
if [ ! -d "$target_dir" ]; then
    echo "指定的目录不存在。"
    exit 1
fi

echo "开始遍历文件"

# 用于记录有序列表的序号
counter=1

# 查找所有 .htm 文件并按文件名中的数字排序

# $( ... )：这是命令替换语法，它会先执行括号内的命令，然后将命令的输出结果作为变量的值。
file_list=$(find "$target_dir" -type f -name "*.htm" \
    | while read -r file; do
    filename=$(basename "$file")
    # echo "文件名: $filename"

    # 提取数字
    number=$(echo "$filename" | grep -o '^[0-9]*')
    # 检查不为空
    if [[ -n "$number" ]]; then
        echo "$number $filename"
    fi
done | sort -n)

# 提取标题
while read -r line; do
    # list中的格式是 数字 空格 文件名。 cut 就是以空格切分，取第二个
    filename=$(echo "$line" | cut -d' ' -f2)
    # 提取二级标题文本

    # IFS=：IFS 是内部字段分隔符（Internal Field Separator），默认包含空格、制表符和换行符。
    # 将 IFS 设为空字符串，意味着在读取输入时不会对行内的内容进行分词处理，会完整地读取每一行。
    # 不写 IFS=  也是可以正常执行的 ？？
    while IFS= read -r heading; do
        # md有序列表+超链接
        echo "${counter}. [${heading}](co/${filename})"
        ((counter++))

    # < <( ... )：这是进程替换的语法，它的作用是将括号内命令的输出作为输入传递给 while 循环。
    done < <(grep -o '<h2 class="title">[^<]*</h2>' "$target_dir/$filename" \
        | sed 's/<h2 class="title">//;s/<\/h2>//')

# <<<：是 Bash 中的 “here string” 操作符。它的作用是把后面紧跟的字符串作为输入提供给前面的命令
done <<< "$file_list"

echo "OK"