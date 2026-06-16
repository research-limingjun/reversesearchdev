---
name: agent-distribution-sync
description: |
  在 Hermes「计划」页配置 12h 数字人 distribution 自动同步（远端检测、profile update、飞书通知）。
  提供：UI 字段清单、脚本模式/no-agent 推荐配置、LLM 模式 prompt、CLI 备用命令、故障排查。
  适用：开启 dist-sync、agent 配置同步、profile update 通知、定时拉取 SOUL/skills。
  不适用：发布 distribution（用 publish.sh）、业务开发任务流程。
---

# Agent Distribution 自动同步

每 12 小时检测 GitHub 远端 `reversesearchdev` distribution 是否有新版本；有更新则 `profile update`，结果通过飞书通知。`.env`、`memories/` 不会被覆盖。

## 快速工作流程

### 路径 A：脚本模式（推荐，零 Token）

若计划页支持「脚本 / no-agent」：

1. 打开 Hermes **计划** → **创建任务**
2. 填写字段：
   - **任务名称**：`agent-distribution-sync`
   - **工作区配置档**：`reversesearchdev`
   - **执行计划**：`every 12h`（或 cron `0 */12 * * *`）
   - **重复次数**：留空（无限循环）
   - **输出通道**：`feishu`
   - **脚本**：`dist-sync-watchdog.sh`（位于 profile 的 `scripts/`）
3. **不填** AI 提示词，**不绑定** skill
4. 保存后点「立即执行」验证；无远端更新时应静默（无飞书消息）

### 路径 B：技能 + 提示词（LLM 模式）

若 UI 仅有「绑定技能 + AI 提示词」：

1. 同上填写名称、配置档、计划、输出通道
2. **绑定技能**：`agent-distribution-sync`
3. **AI 提示词**：

```text
执行 distribution 同步检查：在 profile 目录运行 scripts/dist-sync-watchdog.sh，
将脚本 stdout 原样作为回复；若脚本无输出或远端无更新，仅回复 [SILENT]。
不要自行 profile update，一切逻辑由脚本完成。
```

> LLM 模式每 12h 消耗 Token。优先用路径 A；若无脚本入口，用 CLI：`./scripts/setup-dist-sync-cron.sh`

## 前置条件

- `hermes -p reversesearchdev gateway start` 已运行（调度依赖 gateway）
- `.env` 已配置 `FEISHU_APP_ID`、`FEISHU_APP_SECRET`
- `config.yaml` 中 `FEISHU_HOME_CHANNEL` 已设置

## 执行逻辑（由 dist-sync-watchdog.sh 实现）

| 情况 | 行为 | 飞书 |
|------|------|------|
| 远端 SHA 未变 | 静默退出 | 不发 |
| 有更新且同步成功 | `profile update -y` | 发「已自动更新至 vX.X.X」 |
| 有更新但本机有未发布改动 | 跳过同步 | 发「请先 publish」告警 |

状态文件：`local/dist_sync_state.json`（本机专用，不入 git）

## CLI 备用（Power User）

```bash
cd ~/.hermes/profiles/reversesearchdev
./scripts/setup-dist-sync-cron.sh   # 等效于路径 A 的 no-agent 注册
hermes -p reversesearchdev cron run <job_id>   # 手动触发
```

## 发布者注意

本机有未提交的 `distribution_owned` 改动时，自动同步会跳过并飞书告警，避免覆盖未 `./publish.sh` 的内容。

## 详细 UI 对照

→ [ui-setup.md](references/ui-setup.md)
