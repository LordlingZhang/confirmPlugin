#!/usr/bin/env bash
# ============================================
# 桌面弹窗确认插件 - 安装状态检查
# ============================================

PLUGIN_NAME="confirm-plugin"
PLUGIN_SOURCE="@local"
PLUGIN_KEY="${PLUGIN_NAME}${PLUGIN_SOURCE}"
SETTINGS_FILE="$HOME/.claude/settings.json"
INSTALLED_FILE="$HOME/.claude/plugins/installed_plugins.json"
LINK_PATH="$HOME/.claude/plugins/$PLUGIN_NAME"

PASS=0
FAIL=0

check() {
    local desc="$1"
    local result="$2"
    local fix="$3"
    if [ "$result" -eq 0 ]; then
        echo "  ✅  $desc"
        PASS=$((PASS + 1))
    else
        echo "  ❌  $desc"
        if [ -n "$fix" ]; then
            echo "      → 修复: $fix"
        fi
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║   插件安装状态检查                  ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ---- 1. 软链接 ----
echo "── 插件链接 ──"
if [ -L "$LINK_PATH" ]; then
    target=$(readlink "$LINK_PATH")
    if [ -d "$target" ]; then
        check "插件链接有效 → $target" 0
    else
        check "插件链接存在但目标无效" 1 "重新运行 install.sh"
    fi
else
    check "插件链接不存在" 1 "运行 ./install.sh 创建链接"
fi

# ---- 2. 插件目录结构 ----
echo "── 文件完整性 ──"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
for f in ".claude-plugin/plugin.json" "hooks/hooks.json" "scripts/notify.sh" "scripts/pre-tool-use.sh"; do
    if [ -f "$SCRIPT_DIR/$f" ]; then
        check "$f" 0
    else
        check "$f 缺失" 1 "检查项目文件是否完整"
    fi
done

# ---- 3. 脚本可执行 ----
echo "── 脚本权限 ──"
for s in "install.sh" "uninstall.sh" "scripts/notify.sh" "scripts/pre-tool-use.sh"; do
    if [ -x "$SCRIPT_DIR/$s" ]; then
        check "$s 可执行" 0
    else
        check "$s 不可执行" 1 "chmod +x $SCRIPT_DIR/$s"
    fi
done

# ---- 4. 插件注册 ----
echo "── 插件注册 ──"
if [ -f "$INSTALLED_FILE" ]; then
    if grep -q "$PLUGIN_NAME" "$INSTALLED_FILE"; then
        check "installed_plugins.json 已注册" 0
    else
        check "installed_plugins.json 未注册" 1 "运行 ./install.sh"
    fi
else
    check "installed_plugins.json 文件不存在" 1 "运行 ./install.sh"
fi

# ---- 5. 插件启用 ----
echo "── 插件启用 ──"
if [ -f "$SETTINGS_FILE" ]; then
    if grep -q "$PLUGIN_KEY" "$SETTINGS_FILE"; then
        check "settings.json 已启用" 0
    else
        check "settings.json 未启用" 1 "在 enabledPlugins 中添加 \"$PLUGIN_KEY\": true"
    fi
else
    check "settings.json 文件不存在" 1 "安装 Claude Code 后重试"
fi

# ---- 6. 通知权限 ----
echo "── 通知功能 ──"
notify_result=$(osascript -e 'display notification "check" with title "confirm-plugin"' 2>&1)
if [ $? -eq 0 ]; then
    check "osascript 通知正常" 0
else
    check "osascript 通知失败（可能未授权）" 1 "打开脚本编辑器.app 运行 display notification 并授权"
fi

# ---- 7. python3 ----
echo "── 运行环境 ──"
if command -v python3 &>/dev/null; then
    check "python3 可用" 0
else
    check "python3 不可用" 1 "xcode-select --install"
fi

# ---- 总结 ----
echo ""
echo "  ┌─────────────────────────────────────┐"
echo "  │  通过: $PASS  失败: $FAIL                            │"
if [ "$FAIL" -eq 0 ]; then
    echo "  │  状态: ✅ 插件安装正常               │"
else
    echo "  │  状态: ❌ 存在 $FAIL 个问题，请修复后重试      │"
fi
echo "  └─────────────────────────────────────┘"
echo ""
