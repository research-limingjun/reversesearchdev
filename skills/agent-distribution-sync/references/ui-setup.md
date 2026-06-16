# 计划页字段对照表

对应 Hermes Desktop「创建新任务」表单各区块。

## 基础配置

| UI 字段 | 填写值 | 说明 |
|---------|--------|------|
| 任务名称 | `agent-distribution-sync` | 与 skill 同名，飞书通知标题一致 |
| 工作区配置档 | `reversesearchdev` | 必须选对 profile，否则脚本路径与 source 不对 |

## 执行计划与输出

| UI 字段 | 填写值 | 说明 |
|---------|--------|------|
| 执行计划 | `every 12h` 或 `0 */12 * * *` | 每 12 小时检测一次 |
| 重复次数 | 留空 | 无限重复 |
| 输出通道 | `feishu` | 投递到 `FEISHU_HOME_CHANNEL` |

快捷选项可参考：「每 12 小时」若有；否则选手动输入 `every 12h`。

## 自动化资产

### 脚本模式（推荐）

| UI 字段 | 填写值 |
|---------|--------|
| 脚本 | `agent-sync-watchdog.sh` |
| 绑定技能 | 不添加 |
| AI 提示词 | 留空 |

### LLM 模式（备选）

| UI 字段 | 填写值 |
|---------|--------|
| 绑定技能 | `agent-distribution-sync` |
| AI 提示词 | 见 SKILL.md 路径 B |

## 双向同步行为

| 场景 | 飞书消息 |
|------|----------|
| 无变化 | 无（静默） |
| 本机有改动、远端无新提交 | 「已自动发布至 vX」+ 变更文件列表 |
| 远端有新版本、本机干净 | 「已自动更新至 vX」 |
| 本机与远端均有改动 | 【Distribution】冲突通知 + `distribution/Conflict_*` + GitHub 链接 |

## 验证步骤

1. 确认 gateway 运行：`hermes -p reversesearchdev gateway status`
2. 创建任务后点「立即执行」
3. 查看输出存档：`~/.hermes/profiles/reversesearchdev/cron/output/<job_id>/`
4. 无变化时应无飞书消息；有发布/更新/冲突时应收到对应文案

## 常见错误

| 现象 | 原因 | 处理 |
|------|------|------|
| 任务从不触发 | gateway 未启动 | `hermes -p reversesearchdev gateway start` |
| 执行失败 / 无飞书 | 飞书凭证或 channel 未配 | 检查 `.env` 与 `FEISHU_HOME_CHANNEL` |
| 脚本找不到 | 配置档选错或脚本未同步 | 确认 profile 为 `reversesearchdev`，`profile update` 拉最新 |
| 冲突告警 | 本机与远端同时有未合并改动 | 飞书五步：`checkout` 冲突分支 → `pull origin main --no-rebase` → push → GitHub PR |
| 自动发布失败 | 无 push 权限或 git 错误 | 检查 SSH key 与 `publish.config` 的 `REMOTE` |
| profile update 失败 | Git 权限或 source 缺失 | 检查 `distribution.yaml` 的 `source:` 与 SSH/HTTPS 权限 |

## CLI 等效命令

```bash
hermes -p reversesearchdev cron create "every 12h" \
  --no-agent \
  --script agent-sync-watchdog.sh \
  --deliver feishu \
  --name agent-distribution-sync \
  --profile reversesearchdev
```

或运行仓库内：`./scripts/setup-agent-sync-cron.sh`
