# Git Source 格式

Hermes `profile install` 接受多种 Git 地址写法。用户消息中出现以下任一形式即可提取为 `<SOURCE>`。

## 支持的写法

| 形式 | 示例 |
|------|------|
| GitHub 简写 | `github.com/org/repo` |
| HTTPS | `https://github.com/org/repo.git` |
| SSH | `git@github.com:org/repo.git` |
| 内网 GitLab SSH | `git@git.17usoft.com:flightint/my-agent.git` |
| 带路径的网页链接 | `https://github.com/org/repo`（去掉尾部 `/tree/main` 等路径） |

冲突合并时，飞书通知会根据远端类型生成 Web 链接：GitHub 用 compare URL，GitLab（含 `git.17usoft.com`）用 `/-/merge_requests/new` 新建 MR 链接。

## 提取规则

1. 从用户消息中匹配第一个看起来像 Git 仓库的字符串
2. 去掉首尾引号、反引号、多余空格
3. **不要**要求用户再提供 profile 名、分支名

## 安装命令（固定）

```bash
hermes profile install <SOURCE> --alias -y
```

## 安装 vs 日常更新

| 操作 | 命令 | 何时用 |
|------|------|--------|
| **首次安装** | `hermes profile install <SOURCE> --alias -y` | 本机还没有该 profile |
| **日常更新** | `skills/hermes-distribution/scripts/update.sh` | 已安装，拉取远端新配置 |
| **强制重装** | `hermes profile install <SOURCE> --force --alias -y` | 同名 profile 已存在且用户确认覆盖 |

不要用 `profile install` 代替 `update.sh` 做日常拉取。

## 常见错误

| 现象 | 原因 | 建议 |
|------|------|------|
| `distribution.yaml not found` | 仓库根目录不是 Hermes distribution | 确认仓库含 `distribution.yaml` |
| `profile already exists` | 本机已有同名 profile | 询问是否 `--force` |
| `Permission denied (publickey)` | SSH 无权限 | 配置 GitHub SSH key 或改用 HTTPS |

## 安装后路径

```
~/.hermes/profiles/<name>/
├── distribution.yaml
├── SOUL.md
├── skills/hermes-distribution/
└── .env                  # 用户本地配置，不入 git
```

`name` 来自已安装 profile 的 `distribution.yaml`，不是用户输入。
