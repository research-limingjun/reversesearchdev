---
name: hermes-agent-distribution
description: |
  用户只提供 Git 仓库地址，自动执行 hermes profile install 并完成安装后检查（.env、gateway）。
  提供：Git source 识别规则、默认 install 命令、env_requires 检查、同名 profile 处理。
  适用：安装 agent/数字人、profile install、用户给出 github 链接或 git@ 地址。
  不适用：已安装后的 update/publish、非 distribution 仓库。
---

# Hermes Agent Distribution 安装

用户**只需提供 Git 仓库信息**（一条 URL 或 `github.com/org/repo`）。Agent 提取 SOURCE 后直接安装，**不要追问 profile 名称、分支或 alias 选项**。

## 快速工作流程

1. **从用户消息提取 SOURCE**（唯一必填输入）
   - 识别 `github.com/org/repo`、`https://github.com/org/repo.git`、`git@github.com:org/repo.git` 等
   - 详细格式见 → [source-formats.md](references/source-formats.md)
2. **执行安装**（固定命令，不加 `--name`）

```bash
hermes profile install <SOURCE> --alias -y
```

profile 名称由远端 `distribution.yaml` 的 `name:` 自动决定。

3. **读取安装结果**
   - 确认目录 `~/.hermes/profiles/<name>/`
   - 从该目录的 `distribution.yaml` 读取 `name`、`env_requires`
4. **检查 `.env`**
   - 对照 `env_requires` 列出缺失的必填变量（只列变量名与说明，不写示例密钥）
   - 有 `default` 的可说明将使用默认值
5. **启动 gateway**

```bash
hermes -p <name> gateway start
```

6. **告知后续维护**
   - 若 profile 含 `update.sh`：后续拉取用 `~/.hermes/profiles/<name>/update.sh` 或 `cd` 后 `./update.sh`
   - 可选：提示 teammate 可配置 `agent-distribution-sync` 定时同步

## 关键规则/约束

- **禁止**向用户索要 profile 名称；仅安装失败时再交互
- **禁止**在 SKILL 正文中写死某个 agent 名；示例放 `references/`
- **禁止**猜测或写入密钥；`.env` 由用户自行填写
- 安装 ≠ 发布：发布用目标 profile 的 `publish.sh`，更新用 `update.sh` 或 `hermes profile update`
- 本 skill 仅负责**首次安装**；已安装后的双向同步见 `agent-distribution-sync`

## 仅失败时再问用户

| 错误 | 处理 |
|------|------|
| 同名 profile 已存在 | 询问是否执行 `hermes profile install <SOURCE> --force --alias -y` |
| 仓库无 `distribution.yaml` | 提示非 Hermes distribution 仓库，检查 URL |
| Git 权限/克隆失败 | 提示检查 SSH key 或 HTTPS 凭据 |

## 详细文档

- Git URL 格式与示例 → [source-formats.md](references/source-formats.md)
- 给其他 agent 发布者 → [publisher-note.md](references/publisher-note.md)
