#!/usr/bin/env bash
set -e

# ============================================
# 桌面弹窗确认插件 - 卸载脚本
# ============================================

PLUGIN_NAME="confirm-plugin"
PLUGIN_SOURCE="@local"
PLUGIN_KEY="${PLUGIN_NAME}${PLUGIN_SOURCE}"
SETTINGS_FILE="$HOME/.claude/settings.json"
INSTALLED_FILE="$HOME/.claude/plugins/installed_plugins.json"
LINK_PATH="$HOME/.claude/plugins/$PLUGIN_NAME"

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║   桌面弹窗确认插件 - 卸载程序       ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ---- 删除软链接 ----
if [[ -L "$LINK_PATH" ]]; then
    rm -f "$LINK_PATH"
    echo "[1/3] 已删除插件链接"
else
    echo "[1/3] 未找到插件链接，跳过"
fi

# ---- 从 settings.json 移除 ----
if [[ -f "$SETTINGS_FILE" ]]; then
    python3 -c "
import json

file_path = '$SETTINGS_FILE'
plugin_key = '${PLUGIN_KEY}'

with open(file_path, 'r') as f:
    data = json.load(f)

if 'enabledPlugins' in data and plugin_key in data['enabledPlugins']:
    del data['enabledPlugins'][plugin_key]
    if not data['enabledPlugins']:
        del data['enabledPlugins']

with open(file_path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print('已从 settings.json 移除')
" && echo "[2/3] 已从 settings.json 移除插件" || echo "[2/3] settings.json 无需处理"
else
    echo "[2/3] 未找到 settings.json，跳过"
fi

# ---- 从 installed_plugins.json 移除 ----
if [[ -f "$INSTALLED_FILE" ]]; then
    python3 -c "
import json

file_path = '$INSTALLED_FILE'
plugin_key = '${PLUGIN_KEY}'

with open(file_path, 'r') as f:
    data = json.load(f)

if 'plugins' in data and plugin_key in data['plugins']:
    del data['plugins'][plugin_key]
    if not data['plugins']:
        data['plugins'] = {}

with open(file_path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print('已从 installed_plugins.json 移除')
" && echo "[3/3] 已从 installed_plugins.json 移除" || echo "[3/3] installed_plugins.json 无需处理"
else
    echo "[3/3] 未找到 installed_plugins.json，跳过"
fi

echo ""
echo "  卸载完成！重启 Claude Code 后生效。"
echo "  插件源码目录未被删除，如需彻底清理请手动执行:"
echo "    rm -rf $SCRIPT_DIR"
