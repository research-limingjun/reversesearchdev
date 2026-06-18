# 初始化 Distribution

面向**首个开发者**或**要新建 agent distribution 的其他开发者**。

## 何时用 init

- 本机还没有该 agent 的 profile 目录
- 需要从零搭建可发布的 distribution 仓库

**不要用 init 代替 install**（install = 从已有 Git 仓库克隆）。

## 用户输入

**仅需 agent name**（如 `my-agent`）。init 阶段**禁止**追问 Git remote、分支、冲突策略。

## 执行

```bash
skills/hermes-distribution/scripts/init-distribution.sh <name>
# 或
skills/hermes-distribution/scripts/init-distribution.sh --name <name>
```

若 `~/.hermes/profiles/<name>/` 已存在，使用 `--force` 覆盖脚手架（慎用）。

## init 自动生成

| 文件 | 说明 |
|------|------|
| `distribution.yaml` | name、version 1.0.0、`publish:` 块、`distribution_owned` |
| `SOUL.md` | 占位 |
| `config.yaml` | 可选骨架 |
| `.gitignore` | `.env`、`local/`、`cron/` 等 |
| `skills/hermes-distribution/` | 本 skill（bootstrap） |
| `scripts/agent-sync-watchdog.sh` | cron 入口（调用 skill 内逻辑） |
| `git init` | 初始化仓库，**不自动 push** |

**不生成**：`publish.config`、根目录 `publish.sh`/`update.sh`

## init 完成后告知用户

1. 在 GitHub 创建空仓库（若尚无）
2. 编辑 `SOUL.md`、`distribution.yaml` 的 `env_requires`（环境变量唯一清单）
3. 在本机配置 `.env`（对照 `env_requires`，见 [env-setup.md](env-setup.md)）
4. **首次发布**（写入 `source:` 并推送）：

```bash
skills/hermes-distribution/scripts/publish.sh <git-remote-url>
```

5. 可选：按 [cron-sync.md](cron-sync.md) 配置 12h 双向同步
