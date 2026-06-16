---
name: coding-agents
description: "Delegate coding to external agent CLIs: Claude Code, Codex, OpenCode."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [Coding-Agent, Claude, Codex, OpenCode, OpenAI, Anthropic, PTY, Automation, Refactoring]
    related_skills: [hermes-agent]
---

# External Coding Agent CLIs

Delegate coding tasks to autonomous agent CLIs via the Hermes terminal. Three agents, unified workflow pattern.

## Which Agent?

| Agent | Install | Auth | Best for |
|-------|---------|------|----------|
| **Claude Code** | `npm i -g @anthropic-ai/claude-code` | OAuth or `ANTHROPIC_API_KEY` | Complex reasoning, multi-turn, PR review |
| **Codex** | `npm i -g @openai/codex` | `OPENAI_API_KEY` or OAuth | Quick one-shot tasks, sandboxed execution |
| **OpenCode** | `npm i -g opencode-ai@latest` | Provider-agnostic (`opencode auth login`) | Multi-provider, open-source, TUI sessions |

All three require a **git repository** for code tasks. Use `mktemp -d && git init` for scratch work.

---

## §1 — Claude Code (Anthropic)

Full-featured autonomous coding agent with multi-turn conversation, subagents, and MCP integration.

### Prerequisites

```bash
npm install -g @anthropic-ai/claude-code
claude auth login              # browser OAuth
claude auth login --console    # API key billing
claude --version               # requires v2.x+
```

### One-Shot Mode (Print Mode — Preferred)

```
terminal(command="claude -p 'Add error handling to all API calls in src/' --allowedTools 'Read,Edit' --max-turns 10", workdir="~/project", timeout=120)
```

Key flags: `--max-turns N`, `--max-budget-usd N`, `--model sonnet|opus|haiku`, `--allowedTools`, `--output-format json`

### Interactive Mode (tmux)

```
terminal(command="tmux new-session -d -s claude-work -x 140 -y 40")
terminal(command="tmux send-keys -t claude-work 'cd ~/project && claude' Enter")
terminal(command="sleep 5 && tmux send-keys -t claude-work 'Refactor the auth module' Enter")
terminal(command="sleep 15 && tmux capture-pane -t claude-work -p -S -50")
```

### Dialog Handling

- Trust dialog: just press Enter (default "Yes")
- Permissions dialog (`--dangerously-skip-permissions`): Down then Enter

### PR Review

```
terminal(command="git diff main...branch | claude -p 'Review this diff for bugs and security issues' --max-turns 1", timeout=60)
terminal(command="claude -p 'Review this PR thoroughly' --from-pr 42 --max-turns 10", workdir="~/project", timeout=120)
```

### Key Subcommands

| Command | Purpose |
|---------|---------|
| `claude -p "query"` | Print mode (non-interactive) |
| `claude -c` | Continue last conversation |
| `claude -r "id"` | Resume session |
| `claude auth status` | Check auth |
| `/compact` | Compress context |
| `/review` | Code review |

### Pitfalls

- Interactive mode REQUIRES tmux
- `--dangerously-skip-permissions` dialog defaults to "No" — must send Down+Enter
- Session resumption requires same directory
- Context degradation above 70% window usage — use `/compact`

---

## §2 — Codex (OpenAI)

OpenAI's autonomous coding agent CLI. Sandboxed execution, one-shot focused.

### Prerequisites

```bash
npm install -g @openai/codex
# Auth: OPENAI_API_KEY env var or Codex OAuth
# Must run inside a git repository
# Use pty=true — Codex is interactive
```

### One-Shot Tasks

```
terminal(command="codex exec 'Add dark mode toggle to settings'", workdir="~/project", pty=true)
```

### Sandbox Modes

| Flag | Effect |
|------|--------|
| `--sandbox workspace-write` | Auto-approves file changes in workspace (recommended) |
| `--yolo` | No sandbox, no approvals (fastest, most dangerous) |

> `--full-auto` is deprecated as of v0.136+. Use `--sandbox workspace-write`.

### Background Mode

```
terminal(command="codex exec --sandbox workspace-write 'Refactor the auth module'", workdir="~/project", background=true, pty=true)
process(action="poll", session_id="<id>")
process(action="log", session_id="<id>")
```

### PR Review

```
terminal(command="REVIEW=$(mktemp -d) && git clone https://github.com/user/repo.git $REVIEW && cd $REVIEW && gh pr checkout 42 && codex review --base origin/main", pty=true)
```

### Pitfalls

- Always use `pty=true`
- Git repo required
- Sandbox mode blocks git operations — let Codex finish, then commit yourself
- PATH: may need `export PATH="/usr/local/bin:$PATH"`
- Codex auto-commits — verify with `git log` after

---

## §3 — OpenCode

Provider-agnostic, open-source AI coding agent with TUI and CLI.

### Prerequisites

```bash
npm i -g opencode-ai@latest
opencode auth login         # or set provider env vars
opencode auth list          # verify
```

### One-Shot Tasks

```
terminal(command="opencode run 'Add retry logic to API calls and update tests'", workdir="~/project")
```

Flags: `--model`, `--thinking`, `--file path`, `--variant high|max|minimal`

### Interactive Sessions

```
terminal(command="opencode", workdir="~/project", background=true, pty=true)
process(action="submit", session_id="<id>", data="Implement OAuth refresh flow")
process(action="poll", session_id="<id>")
process(action="log", session_id="<id>")
```

Exit with Ctrl+C (`\x03`), NOT `/exit` (opens agent selector).

### PR Review

```
terminal(command="opencode pr 42", workdir="~/project", pty=true)
```

### Pitfalls

- `opencode run` does NOT need pty; interactive mode does
- `/exit` is NOT valid — use Ctrl+C
- Enter may need to be pressed twice in TUI
- Avoid sharing workdir across parallel sessions

---

## Common Patterns

### Parallel Work with Worktrees

```
terminal(command="git worktree add -b fix/issue-78 /tmp/issue-78 main", workdir="~/project")
terminal(command="codex exec 'Fix issue #78'", workdir="/tmp/issue-78", background=true, pty=true)
terminal(command="codex exec 'Fix issue #99'", workdir="/tmp/issue-99", background=true, pty=true)
```

### Monitoring Long Tasks

```
process(action="list")
process(action="poll", session_id="<id>")
process(action="log", session_id="<id>")
```

### Rules

1. **Prefer one-shot mode** for single tasks — cleaner, no dialog handling
2. **Use tmux/pty for interactive work** — the only reliable way to orchestrate TUIs
3. **Always set `workdir`** — keep the agent focused on the right project
4. **Set limits** — `--max-turns` for Claude, sandbox modes for Codex
5. **Monitor sessions** — check progress before assuming failure
6. **Clean up tmux sessions** — kill when done
7. **Report results** — summarize what changed, files modified, tests passed
