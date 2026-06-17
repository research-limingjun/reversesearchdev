# 拉取与更新

从远端拉取最新 distribution 配置到本机。

## 命令

```bash
cd ~/.hermes/profiles/<name>
skills/hermes-distribution/scripts/update.sh
```

内部调用 `hermes profile update <name> -y`，仅更新 `distribution_owned` 路径。

## 与 publish 的关系

| 本机状态 | 远端状态 | 行为 |
|----------|----------|------|
| 干净 | 无新提交 | `Already up to date` |
| 干净 | 有新提交 | `profile update` 拉取 |
| 有未发布改动 | 无新提交 | **报错**，提示先 `publish.sh` |
| 有未发布改动 | 有新提交（分叉） | 尝试 `agent-divergence-merge.sh` |

## 分叉处理

1. **可干净合并**：自动 `git merge origin/<branch>` → `publish.sh` → 飞书通知（cron 场景）
2. **Git merge 冲突**：`agent-conflict-branch.sh` 推 `distribution/Conflict_*` 分支 → 飞书五步通知
3. **`alert_only` 策略**（`publish.conflict_strategy`）：仅文字告警，不推冲突分支

冲突配置在 `distribution.yaml` 的 `publish:` 块。

## 不会覆盖

- `.env`
- `memories/`
- `local/dist_sync_state.json`

## 手动冲突解决（概要）

```bash
git fetch
git checkout distribution/Conflict_main_<host>_<ts>
git pull origin main --no-rebase   # 解决冲突 → push → GitHub PR
```

合并 PR 后，其他机器下次 `update.sh` 或 cron 自动拉取。

## 常见错误

| 现象 | 处理 |
|------|------|
| 本机有未发布改动 | 先 `publish.sh` |
| profile update 失败 | 检查 `source:` 与 Git 权限 |
| 分叉需人工介入 | 按飞书通知或 conflict 分支流程操作 |
