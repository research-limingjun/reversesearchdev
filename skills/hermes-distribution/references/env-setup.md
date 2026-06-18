# .env 配置指南

安装完成后，在 profile 目录配置本地环境变量。`.env` **不入 git**，`update.sh` **不会覆盖**；`config.yaml` 在 update 时**默认保留**本机修改。

**权威清单**：`distribution.yaml` 的 `env_requires`（飞书必填）；模型凭据按 `config.yaml` 的 `model.provider` 自选。

## 初始化

```bash
cd ~/.hermes/profiles/<name>
touch .env
```

Agent 安装时：先填飞书必填项，再按本机 provider 填对应模型 Key；只列变量名与说明，**不写真实密钥**。

## 必填（飞书 Gateway）

本 distribution 所有安装者都需要飞书接入与通知群：

| 变量 | 说明 |
|------|------|
| `FEISHU_APP_ID` | 飞书开放平台自建应用 App ID |
| `FEISHU_APP_SECRET` | 对应 App Secret |
| `FEISHU_HOME_CHANNEL` | 飞书群 `chat_id`（`oc_` 开头）；cron 与 distribution 同步通知发往此处 |

其余 `FEISHU_*` 项若 manifest 标 `required: false` 且有 `default`，可不填。

**获取 `FEISHU_HOME_CHANNEL`（三步）：**

1. 将飞书机器人拉进目标通知群
2. 群内 `@机器人` 发送 `/set-home`，或从群设置复制 `oc_` 开头的群 ID
3. 写入 `.env`：`FEISHU_HOME_CHANNEL=oc_xxxxxxxx`

每人应填**自己**要接收通知的群；不要共用发布者的群 ID。

## 模型凭据（按 provider）

模型 Key **不是**全员必填。读 `config.yaml` 的 `model.provider` / `model.default`，只配对应 env：

| provider（示例） | 环境变量 |
|------------------|----------|
| `xiaomi`（distribution 默认） | `XIAOMI_API_KEY`；`XIAOMI_BASE_URL` 有 default 可不配 |
| `openai` / `openrouter` 等 | `OPENAI_API_KEY` 或对应 provider 文档中的变量 |

**换模型：**

```bash
hermes -p <name> model
# 或编辑 config.yaml 的 model.provider / model.default，再配对应 .env
```

参考：[Hermes environment-variables](https://hermes-agent.nousresearch.com/docs/reference/environment-variables)

**禁止**因未配 `XIAOMI_API_KEY` 就判定安装失败，除非 `config.yaml` 中 provider 确认为 `xiaomi` 且用户选择沿用默认。

## 验证

```bash
grep -E '^[A-Z][A-Z0-9_]*=' .env
hermes -p <name> gateway start
```

飞书必填项缺失会导致 gateway 或通知失败；模型 Key 缺失则对话/推理不可用。
