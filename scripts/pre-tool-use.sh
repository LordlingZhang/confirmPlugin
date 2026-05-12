#!/usr/bin/env bash
# PreToolUse 钩子处理器 - 当工具需要用户确认时显示桌面弹窗

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"

# 加载通知函数库
source "${PLUGIN_ROOT}/scripts/notify.sh"

# 读取 stdin 中的 hook JSON
HOOK_INPUT=$(cat)

# 解析关键字段
permission_mode=$(echo "$HOOK_INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('permission_mode', 'ask'))
" 2>/dev/null || echo "ask")

tool_name=$(echo "$HOOK_INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('tool_name', 'unknown'))
" 2>/dev/null || echo "unknown")

tool_input=$(echo "$HOOK_INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(json.dumps(data.get('tool_input', {})))
" 2>/dev/null || echo "{}")

# 只在需要用户确认时才弹窗
if [ "$permission_mode" != "ask" ]; then
    echo '{"continue": true}'
    exit 0
fi

# 提取操作摘要
summary=$(extract_summary "$tool_name" "$tool_input")

# 工具名称中文映射
case "$tool_name" in
    Bash) tool_label="终端命令" ;;
    Write) tool_label="写入文件" ;;
    Edit) tool_label="编辑文件" ;;
    MultiEdit) tool_label="批量编辑" ;;
    *) tool_label="$tool_name" ;;
esac

# 发送非阻塞桌面通知
send_notification \
    "小牛马,你的claude code需要你确认下一步!!!" \
    "$tool_label" \
    "$summary"

# 如果是高风险操作并且启用了模态对话框
if [ "$HIGH_RISK_DIALOG" = "true" ] && is_high_risk "$tool_name" "$tool_input"; then
    show_dialog \
        "Claude Code - 高风险操作" \
        "即将执行操作: $summary

请在 Claude Code 窗口中确认此操作。" \
        "知道了" \
        60 > /dev/null 2>&1 &
fi

# 返回继续，不改变原有权限逻辑
echo '{"continue": true}'
