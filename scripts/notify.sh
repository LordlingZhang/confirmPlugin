#!/usr/bin/env bash
# 核心通知库 - 提供 macOS 桌面通知和对话框功能

# 通知声音（可通过环境变量覆盖）
NOTIFY_SOUND="${CONFIRM_PLUGIN_SOUND:-Boop}"

# 高风险操作正则模式（可通过环境变量覆盖）
HIGH_RISK_PATTERNS="${CONFIRM_PLUGIN_HIGH_RISK_PATTERNS:-rm\s+-rf|sudo|chmod\s+777|curl.*\|\s*(ba)?sh|/dev/null.*>}"

# 是否对高风险操作弹模态框（默认 true）
HIGH_RISK_DIALOG="${CONFIRM_PLUGIN_HIGH_RISK_DIALOG:-true}"

# 发送非阻塞桌面通知
send_notification() {
    local title="$1"
    local subtitle="$2"
    local message="$3"

    osascript -e "
        display notification \"$(escape_osascript_str "$message")\" \
        with title \"$(escape_osascript_str "$title")\" \
        subtitle \"$(escape_osascript_str "$subtitle")\" \
        sound name \"$NOTIFY_SOUND\"
    " 2>/dev/null || true
}

# 显示模态确认对话框（带超时）
show_dialog() {
    local title="$1"
    local message="$2"
    local buttons="${3:-确定}"
    local timeout="${4:-120}"

    local result
    result=$(osascript -e "
        display dialog \"$(escape_osascript_str "$message")\" \
        buttons {$(echo "$buttons" | sed 's/,/\",\"/g' | sed 's/^/\"/;s/$/\"/')} \
        default button \"$(echo "$buttons" | cut -d',' -f1)\" \
        with title \"$(escape_osascript_str "$title")\" \
        with icon caution \
        giving up after $timeout
    " 2>/dev/null || true)

    echo "$result"
}

# 转义用于 osascript 字符串的特殊字符
escape_osascript_str() {
    local str="$1"
    # 转义反斜杠和双引号
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    echo "$str"
}

# 从工具输入提取操作摘要
extract_summary() {
    local tool_name="$1"
    local tool_input="$2"

    case "$tool_name" in
        Bash)
            local cmd
            cmd=$(echo "$tool_input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('command','')[:80])" 2>/dev/null || echo "$tool_input")
            echo "命令: ${cmd:0:80}"
            ;;
        Write)
            local file
            file=$(echo "$tool_input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('file_path','')[:80])" 2>/dev/null || echo "$tool_input")
            echo "写入文件: ${file:0:80}"
            ;;
        Edit)
            local file
            file=$(echo "$tool_input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('file_path','')[:80])" 2>/dev/null || echo "$tool_input")
            echo "编辑文件: ${file:0:80}"
            ;;
        MultiEdit)
            local file
            file=$(echo "$tool_input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('file_path','')[:80])" 2>/dev/null || echo "$tool_input")
            echo "批量编辑: ${file:0:80}"
            ;;
        *)
            echo "工具: $tool_name"
            ;;
    esac
}

# 判断是否为高风险操作
is_high_risk() {
    local tool_name="$1"
    local tool_input="$2"

    if [ "$tool_name" = "Bash" ]; then
        local cmd
        cmd=$(echo "$tool_input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('command',''))" 2>/dev/null || echo "$tool_input")
        if echo "$cmd" | grep -qE "$HIGH_RISK_PATTERNS"; then
            return 0
        fi
    fi
    return 1
}

# 当作为 notification 事件处理器调用时
if [ "${1:-}" = "notification" ]; then
    # Notification 事件：读取 stdin，显示通知
    input=$(cat)
    notification_type=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_result',{}).get('notification_type','') if isinstance(d.get('tool_result'),dict) else '')" 2>/dev/null || echo "")
    message=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_result',{}).get('message','') if isinstance(d.get('tool_result'),dict) else '')" 2>/dev/null || echo "")

    if [ -n "$message" ]; then
        send_notification "小牛马,你的claude code需要你确认下一步!!!" "$notification_type" "$message"
    fi

    echo '{"continue": true}'
fi
