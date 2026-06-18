# 其他开发者安装

帮助**其他开发者**在本机首次安装 Hermes 数字人 profile：用户只需提供 Git 仓库地址。

## 快速工作流程

1. **提取 SOURCE**（唯一必填输入）→ [source-formats.md](source-formats.md)

2. **执行安装**（固定命令，不加 `--name`）

```bash
hermes profile install <SOURCE> --alias -y
```

3. **进入 profile 目录**，读取 `distribution.yaml` 的 `name`、`version`、`env_requires`

4. **配置 `.env`**：读 `env_requires`，若本机无 `.env` 则创建并逐项填写（**禁止**猜测密钥）→ [env-setup.md](env-setup.md)

5. **启动 gateway**：`hermes -p <name> gateway start`

6. **验证**：profile 可识别、gateway 无 FEISHU/API Key 类错误

7. **收尾**：用下方报告模板回复；可选提示 12h 同步见 [cron-sync.md](cron-sync.md)

## 关键规则

- **禁止**向用户索要 profile 名称；仅安装失败时再交互
- **禁止**猜测或写入密钥
- **安装 ≠ 日常更新**：拉取用 `skills/hermes-distribution/scripts/update.sh`
- **安装 ≠ 发布**：发布用 `skills/hermes-distribution/scripts/publish.sh`（需 push 权限）
- `.env` 每人本地，`update.sh` **不会覆盖**

## 安装完成报告（Agent 回复模板）

```markdown
## 安装完成

- **Profile**：<name>（v<version>）
- **路径**：~/.hermes/profiles/<name>/

## .env 状态

- 已配置：<变量列表>
- 待配置：<缺失的必填 env_requires>

## Gateway

- 状态：<运行中 / 未启动 / 报错摘要>

## 下一步

- **日常更新**：`cd ~/.hermes/profiles/<name> && skills/hermes-distribution/scripts/update.sh`
- **可选自动同步**：按 cron-sync.md 配置 12h cron
```

## 仅失败时再问用户

| 错误 | 处理 |
|------|------|
| 同名 profile 已存在 | 询问是否 `--force --alias -y` |
| 无 `distribution.yaml` | 提示非 Hermes distribution 仓库 |
| Git 权限失败 | 检查 SSH key 或 HTTPS 凭据 |
