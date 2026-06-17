# 计划页字段对照表

对应 Hermes Desktop「创建新任务」表单各区块。

## 基础配置

| UI 字段 | 填写值 | 说明 |
|---------|--------|------|
| 任务名称 | `agent-distribution-sync` | 与 cron 任务名一致 |
| 工作区配置档 | profile 的 `name` | 必须选对，否则脚本路径与 source 不对 |

## 执行计划与输出

| UI 字段 | 填写值 | 说明 |
|---------|--------|------|
| 执行计划 | `every 12h` 或 `0 */12 * * *` | 每 12 小时检测一次 |
| 重复次数 | 留空 | 无限重复 |
| 输出通道 | `feishu` | 投递到 `FEISHU_HOME_CHANNEL` |

## 自动化资产（脚本模式，推荐）

| UI 字段 | 填写值 |
|---------|--------|
| 脚本 | `agent-sync-watchdog.sh` |
| 绑定技能 | 不添加 |
| AI 提示词 | 留空 |

## 双向同步行为

| 场景 | 飞书消息 |
|------|----------|
| 无变化 | 无（脚本输出 `[SILENT]` 审计行） |
| 本机有改动、远端无新提交 | 「已自动发布至 vX」 |
| 远端有新版本、本机干净 | 「Updated …@vX」 |
| 分叉可干净合并 | 「分叉已自动合并并发布至 vX」 |
| Git merge 冲突 | 【Distribution】冲突通知 |

## 验证步骤

1. `hermes -p <name> gateway status`
2. 创建任务后点「立即执行」
3. 查看 `~/.hermes/profiles/<name>/cron/output/<job_id>/`
4. 无变化时应无飞书消息

## 常见错误

| 现象 | 处理 |
|------|------|
| 任务从不触发 | `hermes -p <name> gateway start` |
| 无飞书 | 检查 `.env` 飞书三项 |
| 脚本找不到 | 确认配置档正确，`update.sh` 拉最新 |
| 自动发布失败 | 检查 SSH key 与 `distribution.yaml` 的 `source:` |

## CLI 等效

```bash
skills/hermes-distribution/scripts/setup-cron.sh
```
