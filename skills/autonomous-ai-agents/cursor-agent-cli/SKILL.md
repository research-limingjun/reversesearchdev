---
name: cursor-agent-cli
description: Call Cursor Agent CLI from Hermes for code editing, debugging, and development tasks. Use when delegating coding work to the local Cursor installation.
category: autonomous-ai-agents
---

# Cursor Agent CLI

Delegate coding tasks to Cursor Agent (local CLI) for code editing, debugging, refactoring, and development.

## Prerequisites

- Cursor CLI installed at `/Users/apple/.local/bin/cursor`
- tmux installed (`brew install tmux`) — required for interactive sessions
- **Authentication**: Cursor IDE login ≠ CLI auth. The CLI requires a separate `CURSOR_API_KEY` environment variable.

### API Key Validation

⚠️ **Always verify the API key before launching tasks.** Keys can expire or be revoked. Quick check:

```bash
export CURSOR_API_KEY="your_key"
cursor agent "hi" 2>&1 | head -3
# If you see "API key is invalid" → key is stale, ask user for a new one
```

Do NOT assume a previously-provided key is still valid. Test first, then launch the tmux session.

## Authentication Pitfall

⚠️ **Critical**: Even if the user is logged into Cursor IDE (auth stored in `~/.cursor/cli-config.json`), the CLI agent will fail with:
```
Error: Authentication required. Please run 'agent login' first, or set CURSOR_API_KEY environment variable.
```

**Fix**: Set the environment variable before calling:
```bash
export CURSOR_API_KEY="your_api_key_here"
cursor agent "your prompt here"
```

To persist, add to `~/.zshrc` or `~/.bashrc`.

## Usage

```bash
# Basic prompt
cursor agent "implement feature X in file Y"

# With working directory
cd /path/to/project && cursor agent "refactor this module"
```

## When to Use Cursor Agent vs Codex CLI

| Tool | Best For |
|------|----------|
| Cursor Agent | Projects already open in Cursor IDE, leveraging Cursor's context |
| Codex CLI | Standalone tasks, OpenAI-powered coding |

## Integration with Hermes

Use `terminal` tool to invoke `cursor agent` commands. Always check `CURSOR_API_KEY` is set first.

## 两种执行模式

### 模式1：One-shot（后台执行，无需用户交互）

适合简单任务，执行完自动退出。**注意：不会在 Cursor IDE Sessions 面板中显示。**

```bash
export CURSOR_API_KEY="your_key"
cursor agent --trust "你的任务描述"
```

- `--trust` 自动批准工作区操作，**只能用于 one-shot / headless 模式**
- 输出直接返回到终端，适合 Hermes 自动化调用
- 不会在 Cursor IDE 中留下 session 记录

### 模式2：Interactive（推荐，用户可交互）

适合需要用户审批、确认、或查看执行过程的任务。**会在 Cursor IDE Sessions 面板中显示。**

```bash
export CURSOR_API_KEY="your_key"
cursor agent
# ⚠️ 不能加 --trust！会报错：--trust can only be used with --print/headless mode
```

- 启动交互式 REPL，用户可以通过 `tmux attach` 接入
- 在 Cursor IDE 的 Sessions 面板中可以看到对话过程
- 用户拥有完全控制权（输入、中断、审批）

## Tmux Interactive Session (推荐)

当任务需要用户交互（Cursor Agent 询问确认、审批操作等）时，**必须**使用 tmux 会话启动。

### 启动方式

```bash
# 1. 创建命名 tmux 会话，在其中启动 Cursor Agent（⚠️ 不能加 --trust）
tmux new-session -d -s "cursor-<task-id>" -c "/path/to/project" \
  "export CURSOR_API_KEY='$CURSOR_API_KEY' && cursor agent; exec bash"

# 2. 等待启动完成（至少 15 秒）
sleep 15

# 3. 确认会话已创建并检查输出
tmux capture-pane -t "cursor-<task-id>" -p | head -10
```

### ⚠️ 关键 Pitfall：`--trust` 不能用于交互模式

```
Error: --trust can only be used with --print/headless mode
```

- ✅ 交互模式：`cursor agent`（不加任何参数）
- ✅ One-shot 模式：`cursor agent --trust "prompt"`（加 `--trust` + 提示词）
- ❌ 错误：`cursor agent --trust`（`--trust` 但没有提示词 → 报错）

### 会话命名规范

```
cursor-<task-id>
```
示例：`cursor-TASK-001`、`cursor-fix-auth-bug`

### 飞书通知模板

启动后发送给用户的飞书消息（post 格式）：

```json
{
  "zh_cn": {
    "title": "🚀 Cursor Agent 已启动",
    "content": [
      [{"tag": "text", "text": "🏷️ 会话名：cursor-TASK-001\n📌 任务：实现功能 X\n📂 项目：/path/to/project\n\n"}],
      [{"tag": "text", "text": "🔍 查看并交互（可直接操作 Cursor Agent）：\n  tmux attach -t cursor-TASK-001\n\n"}],
      [{"tag": "text", "text": "  退出会话（不打断运行）：\n  Ctrl+B 然后按 D\n\n"}],
      [{"tag": "text", "text": "📋 实时日志（只看不交互）：\n  tail -f /tmp/cursor-TASK-001.log"}]
    ]
  }
}
```

### 关键规则

- ⚠️ **交互模式不要加 `--trust`**——会报错，且交互模式下用户可以手动审批
- ⚠️ **不要用 `-r` 只读模式**——用户需要能直接在会话里回复 Cursor Agent 的提问
- ✅ One-shot 模式用 `--trust "prompt"` 自动批准，适合 Hermes 自动化
- ✅ 用户 attach 后拥有完全控制权，可以直接输入、Ctrl+C 中断等
- ✅ 同时 `tee` 到日志文件，方便事后回顾或不 attach 时查看进度（one-shot 模式）

### 用户操作指南

```bash
# 查看所有 Cursor 会话
tmux ls | grep cursor

# 进入会话（完全交互模式）
tmux attach -t cursor-TASK-001

# 退出会话（不打断 Cursor 运行）
# 按 Ctrl+B，然后按 D

# 查看日志（不进入会话）
tail -f /tmp/cursor-TASK-001.log
```

### Hermes 端检查会话状态

```bash
# 检查会话是否还在运行
tmux has-session -t cursor-TASK-001 2>/dev/null && echo "运行中" || echo "已结束"

# 获取会话当前输出（不 attach）
tmux capture-pane -t cursor-TASK-001 -p | tail -20
```
