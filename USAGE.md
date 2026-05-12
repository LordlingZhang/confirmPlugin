# 桌面弹窗确认插件 - 使用文档

## 功能概述

当 Claude Code 执行需要用户确认的操作时，通过 macOS 桌面弹窗主动提醒用户，避免因切换到其他窗口而错过确认提示。

- 支持的工具：`Bash`、`Write`、`Edit`、`MultiEdit`
- 通知类型：桌面横幅通知（非阻塞）+ 高风险操作模态对话框
- 平台要求：macOS（使用原生 `osascript`）

## 安装

### 一键安装（推荐）

在终端中进入插件目录，运行安装脚本：

```bash
cd /path/to/confirmPlugin
./install.sh
```

脚本自动完成：链接插件 → 注册插件 → 启用插件。安装完毕后按屏幕提示授予 macOS 通知权限即可。

### 授权 macOS 通知权限

首次使用前，需要授予 AppleScript 通知权限。打开 **脚本编辑器.app**（在 `/Applications/Utilities/` 中），输入并运行：

```applescript
display notification "初始化" with title "Claude Code 插件"
```

在弹出的权限对话框中点击 **"允许"**。

### 重启 Claude Code

关闭并重新打开 Claude Code 会话，插件即可生效。

---

### 手动安装（备用）

如果一键脚本无法使用，按以下步骤手动安装：

**1. 链接插件到用户插件目录**

```bash
ln -sf "$(pwd)" ~/.claude/plugins/confirm-plugin
```

**2. 注册插件** — 编辑 `~/.claude/plugins/installed_plugins.json`，在 `plugins` 中添加：

```json
"confirm-plugin@local": [
  {
    "scope": "user",
    "installPath": "/Users/<你的用户名>/.claude/plugins/confirm-plugin",
    "version": "1.0.0",
    "installedAt": "2026-05-13T00:00:00.000Z",
    "lastUpdated": "2026-05-13T00:00:00.000Z"
  }
]
```

**3. 启用插件** — 编辑 `~/.claude/settings.json`，在 `enabledPlugins` 中添加：

```json
"confirm-plugin@local": true
```

**4. 配置项目权限** — 在项目的 `.claude/settings.local.json` 中添加：

```json
{
  "permissions": {
    "allow": [
      "Bash(osascript *)",
      "Bash(bash <插件路径>/scripts/*)"
    ]
  }
}
```

## 配置选项

在项目 `.claude/settings.local.json` 或全局 `~/.claude/settings.json` 的 `env` 中设置：

| 环境变量 | 默认值 | 说明 |
|---|---|---|
| `CONFIRM_PLUGIN_SOUND` | `Boop` | 通知提示音 |
| `CONFIRM_PLUGIN_HIGH_RISK_DIALOG` | `true` | 高风险操作是否弹模态框 |
| `CONFIRM_PLUGIN_HIGH_RISK_PATTERNS` | `rm\s+-rf\|sudo\|chmod\s+777\|curl.*\|\s*(ba)?sh` | 高风险命令正则 |

### 可用提示音

`Basso` `Blow` `Bottle` `Frog` `Funk` `Glass` `Hero` `Morse` `Ping` `Pop` `Purr` `Sosumi` `Submarine` `Tink` `Boop` `Mezzo` `Breeze` `Pebble` `Jump` `Funky` `Crystal` `Heroine` `Pong` `Sonar` `Bubble` `Pluck` `Sonumi` `Submerge`

### 配置示例

```json
{
  "env": {
    "CONFIRM_PLUGIN_SOUND": "Glass",
    "CONFIRM_PLUGIN_HIGH_RISK_DIALOG": "false"
  }
}
```

## 验证安装

触发一个需要确认的操作（如让 Claude Code 写文件），确认桌面弹出通知。

也可手动测试通知是否正常：

```bash
osascript -e 'display notification "测试消息" with title "Claude Code" subtitle "写入文件" sound name "Boop"'
```

## 关闭插件

### 方法一：一键卸载（推荐）

```bash
cd /path/to/confirmPlugin
./uninstall.sh
```

脚本自动清理：软链接、`settings.json` 中的启用条目、`installed_plugins.json` 中的注册信息。重启 Claude Code 后生效。插件源码目录不会被删除，可手动 `rm -rf` 清理。

### 方法二：禁用插件（保留配置，可随时重新启用）

编辑 `~/.claude/settings.json`，将 `confirm-plugin@local` 改为 `false`：

```json
"enabledPlugins": {
  "confirm-plugin@local": false
}
```

重启 Claude Code 后插件停用。

### 方法三：手动完全卸载

```bash
# 1. 删除插件链接
rm ~/.claude/plugins/confirm-plugin

# 2. 编辑 ~/.claude/settings.json，移除 enabledPlugins 中的：
#    "confirm-plugin@local": true

# 3. 编辑 ~/.claude/plugins/installed_plugins.json，移除 plugins 中的：
#    "confirm-plugin@local" 整个条目

# 4. （可选）删除插件源码目录
rm -rf /path/to/confirmPlugin
```

## 常见问题

### Q: 通知没有弹出？

1. 检查 macOS 通知权限：打开 **系统设置 > 通知 > 脚本编辑器(Script Editor)**，确保已允许
2. 检查是否开启了"勿扰模式"或"专注模式"
3. 手动运行测试命令确认 `osascript` 是否正常

### Q: 需要确认时没有弹窗？

1. 确认 `permission_mode` 为 `ask`（可在 Claude Code 中用 `/status` 查看）
2. 检查插件是否已启用：查看 `~/.claude/settings.json` 中 `enabledPlugins`
3. 确认已重启 Claude Code

### Q: 弹窗太频繁？

在项目配置中关闭高风险模态框：

```json
{
  "env": {
    "CONFIRM_PLUGIN_HIGH_RISK_DIALOG": "false"
  }
}
```
