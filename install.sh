#!/usr/bin/env bash
set -e

# ============================================
# 桌面弹窗确认插件 - 一键安装脚本
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_NAME="confirm-plugin"
PLUGIN_SOURCE="@local"
SETTINGS_FILE="$HOME/.claude/settings.json"
INSTALLED_FILE="$HOME/.claude/plugins/installed_plugins.json"
LINK_PATH="$HOME/.claude/plugins/$PLUGIN_NAME"

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║   桌面弹窗确认插件 - 安装程序       ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ---- 检测 macOS ----
if [[ "$(uname)" != "Darwin" ]]; then
    echo "[错误] 此插件仅支持 macOS 系统。"
    exit 1
fi

# ---- 检查依赖 ----
echo "[1/6] 检查环境..."

if ! command -v python3 &>/dev/null; then
    echo "[错误] 需要 python3，请先安装 Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

# ---- 创建必要目录 ----
echo "[2/6] 创建目录..."
mkdir -p "$HOME/.claude/plugins"

# ---- 建立软链接 ----
echo "[3/6] 链接插件..."
if [[ -L "$LINK_PATH" ]] || [[ -d "$LINK_PATH" ]]; then
    echo "      已存在旧链接，覆盖..."
    rm -f "$LINK_PATH"
fi
ln -sf "$SCRIPT_DIR" "$LINK_PATH"
echo "      已链接: $LINK_PATH → $SCRIPT_DIR"

# ---- 注册到 installed_plugins.json ----
echo "[4/6] 注册插件..."

if [[ -f "$INSTALLED_FILE" ]]; then
    python3 -c "
import json, os

file_path = '$INSTALLED_FILE'
plugin_key = '${PLUGIN_NAME}@${PLUGIN_SOURCE}'

with open(file_path, 'r') as f:
    data = json.load(f)

if 'plugins' not in data:
    data['plugins'] = {}

data['plugins'][plugin_key] = [{
    'scope': 'user',
    'installPath': '$SCRIPT_DIR',
    'version': '1.0.0',
    'installedAt': '$(date -u +"%Y-%m-%dT%H:%M:%SZ")',
    'lastUpdated': '$(date -u +"%Y-%m-%dT%H:%M:%SZ")'
}]

with open(file_path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
"
    echo "      已注册到 installed_plugins.json"
else
    cat > "$INSTALLED_FILE" << EOF
{
  "version": 2,
  "plugins": {
    "${PLUGIN_NAME}@${PLUGIN_SOURCE}": [
      {
        "scope": "user",
        "installPath": "$SCRIPT_DIR",
        "version": "1.0.0",
        "installedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
        "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
      }
    ]
  }
}
EOF
    echo "      已创建 installed_plugins.json"
fi

# ---- 启用插件 ----
echo "[5/6] 启用插件..."

if [[ -f "$SETTINGS_FILE" ]]; then
    python3 -c "
import json

file_path = '$SETTINGS_FILE'
plugin_key = '${PLUGIN_NAME}@${PLUGIN_SOURCE}'

with open(file_path, 'r') as f:
    data = json.load(f)

if 'enabledPlugins' not in data:
    data['enabledPlugins'] = {}

data['enabledPlugins'][plugin_key] = True

with open(file_path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
"
    echo "      已在 settings.json 中启用插件"
else
    echo "[警告] 未找到 $SETTINGS_FILE，请手动启用"
fi

# ---- 通知权限提醒 ----
echo "[6/6] 完成！"
echo ""
echo "  ┌─────────────────────────────────────────────┐"
echo "  │  请完成以下步骤以完成安装:                  │"
echo "  │                                             │"
echo "  │  1. 打开 脚本编辑器.app                      │"
echo "  │     (在 /Applications/Utilities/ 下)         │"
echo "  │                                             │"
echo "  │  2. 输入并运行:                              │"
echo "  │     display notification \"init\" with title  \"Claude\"│"
echo "  │                                             │"
echo "  │  3. 在弹出的权限对话框中点击「允许」         │"
echo "  │                                             │"
echo "  │  4. 重启 Claude Code                        │"
echo "  └─────────────────────────────────────────────┘"
echo ""
echo "  安装完成！如不需要此插件，运行 uninstall.sh 卸载。"
