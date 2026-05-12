# confirm-plugin

macOS 桌面弹窗确认插件 for Claude Code。当 Claude Code 需要你确认操作时（执行命令、写入文件等），自动弹出桌面通知提醒你。

## 快速开始

```bash
# 1. 克隆项目
git clone https://github.com/LordlingZhang/confirmPlugin.git
cd confirmPlugin

# 2. 一键安装
./install.sh

# 3. 授权通知权限
# 打开 脚本编辑器.app（/Applications/Utilities/ 下）
# 输入并运行: display notification "init" with title "Claude"
# 点击「允许」

# 4. 重启 Claude Code
```

## 环境要求

- macOS 系统
- Claude Code 已安装
- python3（macOS 自带）

## 效果

当 Claude Code 执行以下需要你确认的操作时，自动弹桌面通知：

| 操作类型 | 通知方式 |
|---|---|
| 终端命令 (Bash) | 桌面横幅通知 |
| 写入文件 (Write) | 桌面横幅通知 |
| 编辑文件 (Edit) | 桌面横幅通知 |
| 高风险命令 (rm -rf / sudo / curl \| sh) | 桌面横幅通知 + 模态弹窗 |

## 配置

在 Claude Code 配置中通过环境变量自定义：

```json
{
  "env": {
    "CONFIRM_PLUGIN_SOUND": "Glass",
    "CONFIRM_PLUGIN_HIGH_RISK_DIALOG": "false"
  }
}
```

| 变量 | 默认值 | 说明 |
|---|---|---|
| `CONFIRM_PLUGIN_SOUND` | `Boop` | 通知提示音 |
| `CONFIRM_PLUGIN_HIGH_RISK_DIALOG` | `true` | 高风险操作是否弹模态框 |

## 卸载

```bash
./uninstall.sh
```

## 项目结构

```
confirmPlugin/
├── .claude-plugin/plugin.json   # 插件清单
├── hooks/hooks.json              # 钩子配置
├── scripts/
│   ├── notify.sh                 # 核心通知库
│   └── pre-tool-use.sh           # PreToolUse 处理
├── skills/desktop-notify/        # 技能定义
├── install.sh                    # 一键安装
├── uninstall.sh                  # 一键卸载
└── USAGE.md                      # 完整使用文档
```
