# Hermes Distribution 操作使用文档

面向使用者的中文操作手册。分场景细节见 `references/` 各专题文档。

## 1. 概述

Agent distribution 通过 Git 共享 SOUL、skills、config 等配置。本 skill 覆盖 **init / install / publish / update / cron** 五类操作。

工作目录均为：

```bash
cd ~/.hermes/profiles/<name>
```

## 2. 角色速查

| 你是谁 | 典型操作 |
|--------|----------|
| 首次搭建 distribution | `init-distribution.sh` → 编辑 → `publish.sh` |
| 其他开发者首次安装 | `hermes profile install <GIT> --alias -y` → `.env` → gateway |
| 日常推送改动 | `publish.sh` |
| 拉取他人更新 | `update.sh` |
| 12h 自动同步 | `setup-cron.sh` |

## 3. 常用命令

| 场景 | 命令 |
|------|------|
| 初始化 | `skills/hermes-distribution/scripts/init-distribution.sh <name>` |
| 安装 | `hermes profile install <GIT_URL> --alias -y` |
| 发布 | `skills/hermes-distribution/scripts/publish.sh [REMOTE]` |
| 拉取 | `skills/hermes-distribution/scripts/update.sh` |
| 定时同步 | `skills/hermes-distribution/scripts/setup-cron.sh` |

## 4. 脚本说明

| 脚本 | 作用 |
|------|------|
| `init-distribution.sh` | 新建 profile 脚手架 |
| `publish.sh` | 发布到 Git 远端 |
| `update.sh` | 拉取远端更新 |
| `setup-cron.sh` | 注册 12h cron |
| `agent-sync-watchdog-core.sh` | 双向同步逻辑（由 `profile/scripts/agent-sync-watchdog.sh` 调用） |
| `_lib.sh` | 读取 `distribution.yaml` 配置 |

## 5. 配置要点

### `.env`（每人本地，不入 git）

- `profile install` 后 Hermes **自动生成** `.env.EXAMPLE`（从 `env_requires` 渲染）
- 安装后：`cp .env.EXAMPLE .env`，填写飞书三项 + 按 provider 填模型 Key
- **飞书必填**：`FEISHU_APP_ID`、`FEISHU_APP_SECRET`、`FEISHU_HOME_CHANNEL`
- 详见 [env-setup.md](env-setup.md)

### `config.yaml` 模型

- distribution 发布的 `model.provider` 是团队**推荐默认**，非强制
- 换模型：`hermes -p <name> model`；`update.sh` **不覆盖**本机 config

## 6. 定时同步与失败排查

### 6.1 正常行为

| 情况 | 飞书 |
|------|------|
| 无变更 | 不发（脚本输出 `[SILENT]`） |
| 发布/拉取/冲突 | 发对应通知 |

### 6.2 失败时去哪看

```bash
# 手动复现
hermes -p <name> cron run <job_id>

# 输出存档
ls ~/.hermes/profiles/<name>/cron/output/<job_id>/

# 任务状态（last_error、last_delivery_error）
hermes -p <name> cron list

# 本地审计（飞书投递失败时仍有记录）
cat ~/.hermes/profiles/<name>/local/dist_sync_state.json

# Gateway 必须运行
hermes -p <name> gateway status
```

失败时 watchdog 会在 **stdout** 输出「distribution 定时同步失败」，并写入 `local/dist_sync_state.json` 的 `last_cron_error` / `last_cron_error_message`。

若未配置 `FEISHU_HOME_CHANNEL`，失败消息末尾会提示飞书可能无法送达。

详见 [cron-sync.md](cron-sync.md)。

## 7. reversesearchdev 示例

- Profile：`reversesearchdev`
- 远端：`git@github.com:research-limingjun/reversesearchdev.git`
- Cron 任务名：`agent-distribution-sync`

## 8. 专题文档

- [init.md](init.md) · [install.md](install.md) · [publish.md](publish.md) · [update.md](update.md)
- [cron-sync.md](cron-sync.md) · [env-setup.md](env-setup.md) · [source-formats.md](source-formats.md)
