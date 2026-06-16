# Git Source 格式

Hermes `profile install` 接受多种 Git 地址写法。用户消息中出现以下任一形式即可提取为 `<SOURCE>`。

## 支持的写法

| 形式 | 示例 |
|------|------|
| GitHub 简写 | `github.com/org/repo` |
| HTTPS | `https://github.com/org/repo.git` |
| SSH | `git@github.com:org/repo.git` |
| 带路径的网页链接 | `https://github.com/org/repo`（去掉尾部 `/tree/main` 等路径） |

## 提取规则

1. 从用户消息中匹配第一个看起来像 Git 仓库的字符串
2. 去掉首尾引号、反引号、多余空格
3. 若用户说「安装 xxx」且 xxx 含 `github` 或 `git@`，xxx 即为 SOURCE
4. **不要**要求用户再提供 profile 名、分支名

## 安装命令（固定）

```bash
hermes profile install <SOURCE> --alias -y
```

## 常见错误

| 现象 | 原因 | 建议 |
|------|------|------|
| `distribution.yaml not found` | 仓库根目录不是 Hermes distribution | 确认仓库含 `distribution.yaml` |
| `profile already exists` | 本机已有同名 profile | 询问是否 `--force` |
| `Permission denied (publickey)` | SSH 无权限 | 配置 GitHub SSH key 或改用 HTTPS |
| `Repository not found` | URL 错误或私有仓库无权限 | 核对 org/repo 与访问权限 |

## 安装后路径

```
~/.hermes/profiles/<name>/
├── distribution.yaml   # name、env_requires、source
├── SOUL.md
├── skills/
├── update.sh             # 若发布者提供
└── .env                  # 用户本地配置，不入 git
```

`name` 来自已安装 profile 的 `distribution.yaml`，不是用户输入。
