# 计划页字段对照表

对应 Hermes Desktop「创建新任务」表单各区块。

## 基础配置

| UI 字段 | 填写值 | 说明 |
|---------|--------|------|
| 任务名称 | `dist-sync-12h` | 便于在任务列表识别 |
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
| 脚本 | `dist-sync-watchdog.sh` |
| 绑定技能 | 不添加 |
| AI 提示词 | 留空 |

### LLM 模式（备选）

| UI 字段 | 填写值 |
|---------|--------|
| 绑定技能 | `agent-distribution-sync` |
| AI 提示词 | 见 SKILL.md 路径 B |

## 验证步骤

1. 确认 gateway 运行：`hermes -p reversesearchdev gateway status`
2. 创建任务后点「立即执行」
3. 查看输出存档：`~/.hermes/profiles/reversesearchdev/cron/output/<job_id>/`
4. 无更新时应无飞书消息；有更新或跳过时应收到对应文案

## 常见错误

| 现象 | 原因 | 处理 |
|------|------|------|
| 任务从不触发 | gateway 未启动 | `hermes -p reversesearchdev gateway start` |
| 执行失败 / 无飞书 | 飞书凭证或 channel 未配 | 检查 `.env` 与 `FEISHU_HOME_CHANNEL` |
| 脚本找不到 | 配置档选错或脚本未同步 | 确认 profile 为 `reversesearchdev`，`profile update` 拉最新 |
| 一直提示跳过同步 | 本机有未 publish 改动 | `./publish.sh` 或 `git stash` 后手动 update |
| profile update 失败 | Git 权限或 source 缺失 | 检查 `distribution.yaml` 的 `source:` 与 SSH/HTTPS 权限 |

## CLI 等效命令

```bash
hermes -p reversesearchdev cron create "every 12h" \
  --no-agent \
  --script dist-sync-watchdog.sh \
  --deliver feishu \
  --name dist-sync-12h \
  --profile reversesearchdev
```

或运行仓库内：`./scripts/setup-dist-sync-cron.sh`
