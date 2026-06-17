---
name: hermes-agent-distribution
description: |
  其他开发者首次安装 Hermes 数字人：用户只给 Git 地址 → profile install → 配 .env → 启 gateway → 验证。
  提供：SOURCE 识别、固定 install 命令、env_requires/.env.EXAMPLE 对照、FEISHU_HOME_CHANNEL 配置、安装完成报告模板。
  适用：安装 agent/数字人、profile install、粘贴 github 或 git@ 链接。
  不适用：已安装后的 update/publish/12h 同步（见 agent-distribution-sync）、非 distribution 仓库。
---

# Hermes Agent Distribution 安装

帮助**其他开发者**在本机首次安装 Hermes 数字人 profile：用户只需提供 Git 仓库地址，Agent 完成安装、配置检查与 gateway 启动，**不要追问 profile 名称、分支或 alias 选项**。

## 与 agent-distribution-sync 的分工

| 场景 | 用哪个 |
|------|--------|
| 首次安装 profile | **本 skill**（`hermes-agent-distribution`） |
| 已安装后的 12h 自动同步 | `agent-distribution-sync` |
| 手动拉取远端最新配置 | 不用 skill，在 profile 目录执行 `./update.sh` |
| 发布本机改动到远端 | 不用 skill，执行 `./publish.sh`（需 push 权限） |

## 用户会怎么说（示例）

- 「安装 `github.com/org/repo`」
- 「帮我装这个 agent：<git url>」
- 直接粘贴 SSH / HTTPS 仓库链接

## 快速工作流程

1. **提取 SOURCE**（唯一必填输入）
   - 识别 `github.com/org/repo`、`https://...`、`git@github.com:...` 等
   - **完成标志**：得到非空 Git 地址 → 详见 [source-formats.md](references/source-formats.md)

2. **执行安装**（固定命令，不加 `--name`）

```bash
hermes profile install <SOURCE> --alias -y
```

   - **完成标志**：`~/.hermes/profiles/<name>/` 目录存在；`name` 来自远端 `distribution.yaml`

3. **读取 manifest**

```bash
cd ~/.hermes/profiles/<name>
```

   - 从 `distribution.yaml` 读取 `name`、`version`、`env_requires`
   - **完成标志**：已知 profile 名与必填环境变量清单

4. **配置 `.env`**
   - 若无 `.env`：`cp .env.EXAMPLE .env`
   - 对照 `env_requires` 检查必填项（只列变量名与说明，**不写示例密钥**）
   - `FEISHU_HOME_CHANNEL` 每人不同，写在 `.env`，**不在 `config.yaml`**
   - **完成标志**：所有必填 `env_requires` 在 `.env` 中均已非空 → 详见 [env-setup.md](references/env-setup.md)

5. **启动 gateway**

```bash
hermes -p <name> gateway start
```

   - **完成标志**：gateway 进程在运行（`hermes gateway status` 或等价检查无报错）

6. **验证安装**
   - `hermes -p <name>` 可识别该 profile
   - gateway 日志无 FEISHU / API Key 类配置错误
   - **完成标志**：上述检查通过，或已向用户说明待补项

7. **收尾告知**
   - 用下方「安装完成报告」模板回复用户
   - **可选**：提示需要 12h 自动同步时，按 `agent-distribution-sync` skill 在「计划」页配置 cron

## 关键规则/约束

- **禁止**向用户索要 profile 名称；仅安装失败时再交互
- **禁止**在 SKILL 正文中写死某个 agent 名；示例放 `references/`
- **禁止**猜测或写入密钥；`.env` 由用户自行填写
- **安装 ≠ 日常更新**：拉远端配置用 `./update.sh`；重装才用 `profile install --force`
- **安装 ≠ 发布**：发布用 profile 目录的 `./publish.sh`
- `.env` 每人本地，`./update.sh` **不会覆盖**
- 全文称呼用「其他开发者」，不用「队友」

## 安装完成报告（Agent 回复模板）

安装流程结束后，按此结构回复（缺项标为「待配置」）：

```markdown
## 安装完成

- **Profile**：<name>（v<version>）
- **路径**：~/.hermes/profiles/<name>/

## .env 状态

- 已配置：<变量列表>
- 待配置：<缺失的必填 env_requires 及说明>

## Gateway

- 状态：<运行中 / 未启动 / 报错摘要>

## 下一步

- **日常更新**：`cd ~/.hermes/profiles/<name> && ./update.sh`
- **可选自动同步**：按 `agent-distribution-sync` skill 配置 12h cron（需 `FEISHU_HOME_CHANNEL`）
```

## 仅失败时再问用户

| 错误 | 处理 |
|------|------|
| 同名 profile 已存在 | 询问是否 `hermes profile install <SOURCE> --force --alias -y` |
| 仓库无 `distribution.yaml` | 提示非 Hermes distribution 仓库，检查 URL |
| Git 权限/克隆失败 | 提示检查 SSH key 或 HTTPS 凭据 |

## 详细文档

- `.env` 配置与 `FEISHU_HOME_CHANNEL` → [env-setup.md](references/env-setup.md)
- Git URL 格式与安装/更新区分 → [source-formats.md](references/source-formats.md)
- 给其他 agent 发布者 → [publisher-note.md](references/publisher-note.md)
