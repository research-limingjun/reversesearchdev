---
name: agent-distribution-sync
description: |
  在 Hermes「计划」页配置 12h 数字人 distribution 双向自动同步（本地发布、远端拉取、冲突告警、飞书通知）。
  提供：UI 字段清单、脚本模式/no-agent 推荐配置、LLM 模式 prompt、CLI 备用命令、故障排查。
  适用：开启 dist-sync、agent 配置同步、profile update 通知、定时拉取/推送 SOUL/skills。
  不适用：业务开发任务流程（非 distribution 文件）。
---

# Agent Distribution 双向自动同步

每 12 小时检测本机 `distribution_owned` 与 GitHub 远端 `reversesearchdev` distribution 的差异：

- **本机有未发布改动**且远端无新提交 → 自动 `./publish.sh` 推送
- **远端有新版本**且本机干净 → `profile update` 拉取
- **双方都有新改动**（分叉）→ 自动推 `distribution/Conflict_*` 分支 + 飞书五步操作通知
- **均无变化** → 静默

`.env`、`memories/` 不会被覆盖。

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
   - **脚本**：`agent-sync-watchdog.sh`（位于 profile 的 `scripts/`）
3. **不填** AI 提示词，**不绑定** skill
4. 保存后点「立即执行」验证；无变化时应静默（无飞书消息）

### 路径 B：技能 + 提示词（LLM 模式）

若 UI 仅有「绑定技能 + AI 提示词」：

1. 同上填写名称、配置档、计划、输出通道
2. **绑定技能**：`agent-distribution-sync`
3. **AI 提示词**：

```text
执行 distribution 双向同步：在 profile 目录运行 scripts/agent-sync-watchdog.sh，
将脚本 stdout 原样作为回复；若脚本无输出（无变化），仅回复 [SILENT]。
不要自行 publish 或 profile update，一切逻辑由脚本完成。
```

> LLM 模式每 12h 消耗 Token。优先用路径 A；若无脚本入口，用 CLI：`./scripts/setup-agent-sync-cron.sh`

## 前置条件

- `hermes -p reversesearchdev gateway start` 已运行（调度依赖 gateway）
- `.env` 已配置 `FEISHU_APP_ID`、`FEISHU_APP_SECRET`
- `config.yaml` 中 `FEISHU_HOME_CHANNEL` 已设置
- 本机对 `distribution.yaml` 中 `source` 仓库有 push 权限（自动发布需要）

## 执行逻辑（由 agent-sync-watchdog.sh 实现）

| 情况 | 行为 | 飞书 |
|------|------|------|
| 本地与远端均无变化 | 静默退出 | 不发 |
| 仅本机有未发布改动 | 自动 `./publish.sh` | 发「已自动发布至 vX.X.X」+ 变更文件 |
| 仅远端有新提交 | `profile update -y` | 发「已自动更新至 vX.X.X」 |
| 本机与远端均有新改动（分叉） | 推 `distribution/Conflict_*` 分支，main 恢复干净 | 发【Distribution】冲突通知 + GitHub 链接 |
| publish / update 失败 | 不更新 state | 发错误摘要 |

状态文件：`local/dist_sync_state.json`（本机专用，不入 git）

## 风险说明

**所有安装了该 cron 的机器均会尝试自动 publish。** 冲突时会推 `distribution/Conflict_*` 分支并发飞书五步通知。

## 冲突处理

`CONFLICT_STRATEGY=distribution_branch`（默认）时自动 WIP commit → push 冲突分支 → reset 本机 main。

```bash
git fetch && git checkout distribution/Conflict_main_<...>
git pull origin main --no-rebase   # Diff 解决 → push → GitHub 合并 PR
```

备选：`git worktree add ~/reversesearchdev-merge distribution/Conflict_main_<...>`

`CONFLICT_STRATEGY=alert_only` 恢复仅文字告警。

## CLI 备用（Power User）

```bash
cd ~/.hermes/profiles/reversesearchdev
./scripts/setup-agent-sync-cron.sh   # 等效于路径 A 的 no-agent 注册
hermes -p reversesearchdev cron run <job_id>   # 手动触发
```

## 发布者注意

手动发布仍可用 `./publish.sh`；cron 会在检测到未发布改动时自动调用同一脚本。

## 详细 UI 对照

→ [ui-setup.md](references/ui-setup.md)
