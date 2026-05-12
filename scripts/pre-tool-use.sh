#!/usr/bin/env bash
# PreToolUse 钩子处理器 - 当工具需要用户确认时显示桌面弹窗

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
LOG_FILE="/tmp/confirm-plugin.log"

# 加载通知函数库
source "${PLUGIN_ROOT}/scripts/notify.sh"

# 诊断日志
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "===== Hook 触发 ====="

# 读取 stdin 中的 hook JSON
HOOK_INPUT=$(cat)
log "Hook input: $HOOK_INPUT"

# 解析关键字段
permission_mode=$(echo "$HOOK_INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('permission_mode', 'ask'))
" 2>/dev/null || echo "ask")
log "permission_mode=$permission_mode"

tool_name=$(echo "$HOOK_INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('tool_name', 'unknown'))
" 2>/dev/null || echo "unknown")
log "tool_name=$tool_name"

tool_input=$(echo "$HOOK_INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(json.dumps(data.get('tool_input', {})))
" 2>/dev/null || echo "{}")
log "tool_input=$tool_input"

# 提取操作摘要
summary=$(extract_summary "$tool_name" "$tool_input")
log "summary=$summary"

# 工具名称中文映射
case "$tool_name" in
    Bash) tool_label="终端命令" ;;
    Write) tool_label="写入文件" ;;
    Edit) tool_label="编辑文件" ;;
    MultiEdit) tool_label="批量编辑" ;;
    WebSearch) tool_label="网络搜索" ;;
    WebFetch) tool_label="网络请求" ;;
    *) tool_label="$tool_name" ;;
esac

# 判断是否需要通知：Bash/WebSearch/WebFetch 始终通知，其他工具仅 ask 模式通知
case "$tool_name" in
    Bash|WebSearch|WebFetch) ;;
    *)
        if [ "$permission_mode" != "ask" ]; then
            log "跳过: $tool_name permission_mode=$permission_mode"
            echo '{"continue": true}'
            exit 0
        fi
        ;;
esac

log "准备发送通知: title=小牛马,你的claude code需要你确认下一步!!! subtitle=$tool_label message=$summary"

# 发送非阻塞桌面通知（去掉 stderr 重定向以便捕获错误）
notify_err=$(osascript -e "
display notification \"$(escape_osascript_str "$summary")\" \
with title \"$(escape_osascript_str "小牛马,你的claude code需要你确认下一步!!!")\" \
subtitle \"$(escape_osascript_str "$tool_label")\" \
sound name \"$NOTIFY_SOUND\"
" 2>&1)

if [ $? -eq 0 ]; then
    log "通知发送成功"
else
    log "通知发送失败: $notify_err"
fi

# 如果是高风险操作并且启用了模态对话框
if [ "$HIGH_RISK_DIALOG" = "true" ] && is_high_risk "$tool_name" "$tool_input"; then
    log "高风险操作，弹出模态对话框"
    show_dialog \
        "Claude Code - 高风险操作" \
        "即将执行操作: $summary

请在 Claude Code 窗口中确认此操作。" \
        "知道了" \
        60 > /dev/null 2>&1 &
fi

# 返回继续，不改变原有权限逻辑
log "返回 continue=true"
echo '{"continue": true}'
