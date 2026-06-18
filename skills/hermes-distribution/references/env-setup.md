# .env 配置指南

安装完成后，在 profile 目录配置本地环境变量。`.env` **不入 git**，`update.sh` **不会覆盖**。

**唯一权威清单**：`distribution.yaml` 的 `env_requires`（无 `.env.EXAMPLE`）。

## 初始化

```bash
cd ~/.hermes/profiles/<name>
# 若 .env 不存在，创建空文件后按 env_requires 逐项填写
touch .env
```

Agent 安装时：从 `env_requires` 列出必填项（`required` 非 false 且无 `default`），引导用户写入 `.env`；只列变量名与说明，**不写真实密钥**。

下面为常见分组（具体以已安装 manifest 的 `env_requires` 为准）。

## 必填分组

### 模型（对话 / 推理）

| 变量 | 说明 |
|------|------|
| `XIAOMI_API_KEY` | 小米 Mimo API Key（若 manifest 要求） |
| `XIAOMI_BASE_URL` | 可选，manifest 有 `default` 时可不配 |

### 飞书 Gateway（机器人接入）

| 变量 | 说明 |
|------|------|
| `FEISHU_APP_ID` | 飞书开放平台自建应用 App ID |
| `FEISHU_APP_SECRET` | 对应 App Secret |

其余 `FEISHU_*` 项若 manifest 标 `required: false` 且有 `default`，可不填。

### 通知群（每人不同）

| 变量 | 说明 |
|------|------|
| `FEISHU_HOME_CHANNEL` | 飞书群 `chat_id`（`oc_` 开头）；cron `--deliver feishu` 与 distribution 同步通知发往此处 |

**获取 `FEISHU_HOME_CHANNEL`（三步）：**

1. 将飞书机器人拉进目标通知群
2. 群内 `@机器人` 发送 `/set-home`，或从群设置复制 `oc_` 开头的群 ID
3. 写入 `.env`：`FEISHU_HOME_CHANNEL=oc_xxxxxxxx`

每人应填**自己**要接收通知的群；不要共用发布者的群 ID。

## 可选

| 变量 | 说明 |
|------|------|
| `OPENAI_API_KEY` | 备用 OpenAI 兼容 Key（manifest 标 optional 时） |

## 验证

```bash
grep -E '^[A-Z][A-Z0-9_]*=' .env
hermes -p <name> gateway start
```

若 `env_requires` 中有未填必填项，gateway 可能启动但通知或模型调用会失败。
