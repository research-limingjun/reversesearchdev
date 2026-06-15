# 飞书用户/机器人 ID 对照表

> **2026-06-08 更新**：`lark-cli --msg-type post` 的 zh_cn JSON 格式支持 `open_id`（`ou_` 开头），不需要短格式 `user_id`。

## 用户

| 姓名 | user_id | 备注 |
|------|---------|------|
| 李明俊 | 9c964871 | 项目负责人 |

## 群组

> ⚠️ **原则：chat_id 必须动态查询，不得硬编码。** 以下 chat_id 仅供参考，实际使用时应通过 `lark-cli im +chats-list` 或其他方式动态获取目标群组的 chat_id。

| 群组ID | 名称 | 备注 |
|--------|------|------|
| `oc_679c37d616217fa4350272e332a0dc64` | 退改航需求对接群 | 仅供参考 |
| `oc_1b1ba935a435557b4462aaeede797e7f` | 备用群组 | 仅供参考 |

## 群内 Bot（open_id，可直接用于 lark-cli --msg-type post）

| 名称 | open_id | 备注 |
|------|---------|------|
| 退改航manager | ou_f2d589556428f147b6c1d31a50d93a3d | Manager - 需求分析拆解和任务调度 |
| 改签核心开发 | ou_b57a12a362e8c22e45884f10b96978af | Dev Agent - changecore 项目 |
| 改签核心测试 | ou_396ed718a30720845e0b28bcc24337a1 | Test Agent - changecore 项目 |
| 改签搜索开发 | ou_b5c2236b558563fdd534ab8d1743a28c | Dev Agent - reversesearch 项目 |
| 改签搜索测试 | ou_a046991c55781257d9c15105b6dce248 | Test Agent - reversesearch 项目 |

## @ 格式（唯一可靠方式）

**必须用 `lark-cli --msg-type post` + zh_cn JSON：**

```bash
lark-cli im +messages-send --chat-id "$CHAT_ID" \
  --content '{"zh_cn":{"title":"","content":[[{"tag":"at","user_id":"ou_xxx"},{"tag":"text","text":" 消息内容"}]]}}' \
  --msg-type post --as bot
```

## 各方式对比

| 方式 | @ 语法 | open_id 支持 | 可靠性 |
|------|--------|-------------|--------|
| `--msg-type post` + zh_cn JSON | `{"tag":"at","user_id":"ou_xxx"}` | ✅ 支持 | ✅ 最可靠 |
| `--content` text JSON | `<at user_id="ou_xxx">` | ❌ 不生效 | ❌ @ 不解析 |
| `--markdown` | `<at id=ou_xxx>` | ❌ 不生效 | ❌ @ 不解析 |
| `send_message` 工具 | `<at id=ou_xxx>` | ❌ 不生效 | ❌ @ 不解析 |

## open_id vs user_id

| 字段 | 格式 | 用途 |
|------|------|------|
| `open_id` | `ou_` 开头 | `lark-cli --msg-type post` 的 zh_cn JSON 中 @mention ✅ |
| `user_id` | 短格式（如 `9c964871`） | `send_message`、`--markdown`、`--content` text 模式 @mention（不可靠） |

> ⚠️ 统一用 `lark-cli --msg-type post`，直接用 open_id，避免兼容性问题。
