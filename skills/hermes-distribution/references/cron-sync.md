# 12h 双向自动同步

每 12 小时检测本机 `distribution_owned` 与 Git 远端的差异，自动 publish / pull / 冲突处理。

## 行为摘要

| 情况 | 行为 | 飞书 |
|------|------|------|
| 均无变化 | 静默（输出 `[SILENT]` 审计行） | 不发 |
| 仅本机有改动 | 自动 `publish.sh` | 发「已自动发布至 vX」 |
| 仅远端有新提交 | `update.sh` | 发「Updated …@vX」 |
| 分叉可合并 | merge + publish | 发「分叉已自动合并并发布」 |
| Git merge 冲突 | 推 `distribution/Conflict_*` | 发【Distribution】冲突通知 |
| 失败 | 不更新 state | 发错误摘要 |

## 路径 A：脚本模式（推荐）

Hermes **计划** → **创建任务**：

| 字段 | 值 |
|------|-----|
| 任务名称 | `agent-distribution-sync` |
| 工作区配置档 | profile 的 `name`（如 `reversesearchdev`） |
| 执行计划 | `every 12h` |
| 输出通道 | `feishu` |
| 脚本 | `agent-sync-watchdog.sh`（位于 `profile/scripts/`） |
| 绑定技能 | 不添加 |
| AI 提示词 | 留空 |

## 路径 B：CLI

```bash
cd ~/.hermes/profiles/<name>
skills/hermes-distribution/scripts/setup-cron.sh
hermes -p <name> cron run <job_id>
```

## 前置条件

- `hermes -p <name> gateway start` 已运行
- `.env` 已配置 `FEISHU_APP_ID`、`FEISHU_APP_SECRET`、`FEISHU_HOME_CHANNEL`
- 本机对 `source` 仓库有 push 权限（自动发布需要）

## 架构说明

- **Cron 入口**：`profile/scripts/agent-sync-watchdog.sh`（Hermes 只认此路径）
- **业务逻辑**：`skills/hermes-distribution/scripts/agent-sync-watchdog-core.sh`
- **状态文件**：`local/dist_sync_state.json`（本机专用，不入 git）

## 路径 C：LLM 模式（备选，耗 Token）

绑定 `hermes-distribution`，提示词：

```text
执行 distribution 双向同步：在 profile 目录运行 scripts/agent-sync-watchdog.sh，
将脚本 stdout 原样作为回复；若仅 [SILENT] 行则无实质变化。
不要自行 publish 或 profile update，一切逻辑由脚本完成。
```

## 详细 UI 对照

→ [ui-setup.md](ui-setup.md)

## 风险

所有安装了该 cron 的机器均会尝试自动 publish。仅 Git merge 真冲突时才推冲突分支。
