# 发布 Distribution

将本机 `distribution_owned` 文件推送到 Git 远端。

## 命令

```bash
cd ~/.hermes/profiles/<name>
skills/hermes-distribution/scripts/publish.sh [REMOTE] [--dry-run]
```

| 参数 | 说明 |
|------|------|
| `REMOTE` | Git 地址；省略时用 `distribution.yaml` 的 `source:` 或 `git remote get-url origin` |
| `--dry-run` | 预览 staged 文件，不 bump 版本、不 commit/push |

## 配置（distribution.yaml）

```yaml
name: my-agent
version: 1.0.0
source: git@github.com:org/repo.git   # 首次 publish 时写入
publish:
  branch: main
  conflict_strategy: distribution_branch
  conflict_branch_prefix: distribution/Conflict
distribution_owned:
  - SOUL.md
  - skills
  - ...
```

**无 `publish.config`**。所有发布/冲突配置从 manifest 读取。

## 行为

1. 若传入 `REMOTE` 或 `source:` 为空，写入 `source:`
2. 自动 bump patch 版本（`1.0.32` → `1.0.33`）
3. stage `distribution_owned` 路径
4. commit + push `origin/<branch>` + tag `v<version>`

## 首次发布

init 后 `source:` 为空，需显式传 remote：

```bash
skills/hermes-distribution/scripts/publish.sh git@github.com:org/my-agent.git
```

## 发布前检查

- `.env`、`local/`、`cron/` 已在 `.gitignore`
- `skills/hermes-distribution/` 随 `skills` 一并发布
- 对其他开发者：提供 Git 地址 + `hermes-distribution` skill

## 成功输出示例

```text
Published my-agent@1.0.33
  其他开发者安装：提供 Git 地址 + hermes-distribution skill
  或：hermes profile install <REMOTE> --alias -y
  后续拉取：skills/hermes-distribution/scripts/update.sh
```
