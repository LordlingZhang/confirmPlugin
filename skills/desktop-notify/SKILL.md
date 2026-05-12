---
name: desktop-notify
description: 当 Claude Code 需要用户确认操作时，通过 macOS 桌面弹窗主动提醒用户
---

# 桌面弹窗确认技能

## 功能

当 Claude Code 执行需要用户确认的操作时（如 Bash 命令、文件写入/编辑）：

1. 发送 macOS 桌面横幅通知，提醒用户回到 Claude Code 确认操作
2. 对于高风险操作（如 `rm -rf`、`sudo`、`curl | sh`），额外弹出模态对话框

## 触发条件

- 工具: `Bash`、`Write`、`Edit`、`MultiEdit`
- 权限模式: 需要询问用户 (`permission_mode = "ask"`)

## 配置

可通过环境变量自定义行为:

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CONFIRM_PLUGIN_SOUND` | `Boop` | 通知声音名称 |
| `CONFIRM_PLUGIN_HIGH_RISK_DIALOG` | `true` | 是否对高风险操作弹模态框 |
| `CONFIRM_PLUGIN_HIGH_RISK_PATTERNS` | `rm\s+-rf\|sudo\|chmod\s+777\|curl.*\|\s*(ba)?sh` | 高风险命令正则 |

### 可用声音

`Basso`, `Blow`, `Bottle`, `Frog`, `Funk`, `Glass`, `Hero`, `Morse`, `Ping`, `Pop`, `Purr`, `Sosumi`, `Submarine`, `Tink`, `Boop`, `Mezzo`, `Breeze`, `Pebble`, `Jump`, `Funky`, `Crystal`, `Heroine`, `Pong`, `Sonar`, `Bubble`, `Pluck`, `Sonumi`, `Submerge`

### 配置示例

在 `.claude/settings.local.json` 中:

```json
{
  "env": {
    "CONFIRM_PLUGIN_SOUND": "Crystal",
    "CONFIRM_PLUGIN_HIGH_RISK_DIALOG": "true"
  }
}
```

## 已知限制

- 仅支持 macOS（使用 `osascript` 原生通知）
- macOS Sequoia (15.x) 上首次使用可能需要先打开"脚本编辑器"运行一次 `display notification` 授予权限
- `display notification` 在"勿扰模式"或"专注模式"下可能不显示
