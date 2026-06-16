---
name: feishu-mentions
description: "飞书群内 @ 提及：机器人互@、@人类用户、通用 @ 格式"
version: 2.0.0
metadata:
  hermes:
    tags: [feishu, lark, mention, bot, at-mention, collaboration]
---

# 飞书 @ 提及技能

## 🚨 第一原则：禁止使用写死的群ID！

**所有发送消息的操作必须使用当前会话的实际 chat_id，绝对不能用技能里写死的 chat_id。**

**正确做法：** 每次发送消息前，先执行查询命令获取当前正确的 chat_id，赋值给 `$CHAT_ID` 变量，然后在所有命令中使用 `$CHAT_ID`。

---

## §1 — @ 机器人

飞书群内机器人互相 @ 的方法。

### 获取机器人 open_id

```bash
# 通过飞书 API 获取机器人信息
curl -s -X GET "https://open.feishu.cn/open-apis/bot/v3/info" \
  -H "Authorization: Bearer $TENANT_ACCESS_TOKEN"
```

### @ 机器人的消息格式

在消息体中使用 `<at user_id="open_id">机器人名称</at>` 格式：

```json
{
  "msg_type": "text",
  "content": {
    "text": "<at user_id=\"ou_xxxxx\">BotName</at> 请帮忙处理这个任务"
  }
}
```

### 注意事项

- 机器人只能被 @ 一次，重复 @ 无效
- @ 标签必须在消息的 `text` 字段中
- open_id 是机器人的唯一标识，不会变化

---

## §2 — @ 人类用户

飞书群内 @ 人类用户的方法。

### 查找用户 union_id

```bash
# 通过手机号或邮箱查找用户
curl -s -X POST "https://open.feishu.cn/open-apis/contact/v3/users/batch" \
  -H "Authorization: Bearer $TENANT_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user_ids": ["ou_xxxxx"]}'
```

### @ 用户的消息格式

```json
{
  "msg_type": "text",
  "content": {
    "text": "<at user_id=\"ou_xxxxx\">用户名</at> 请查看这个issue"
  }
}
```

### 通过群成员列表获取 user_id

```bash
# 获取群成员列表
curl -s -X GET "https://open.feishu.cn/open-apis/im/v1/chats/$CHAT_ID/members" \
  -H "Authorization: Bearer $TENANT_ACCESS_TOKEN"
```

---

## §3 — 通用 @ 格式

### 文本消息中的 @

```
<at user_id="ou_xxxxx">显示名称</at>
```

### 富文本消息中的 @

```json
{
  "tag": "at",
  "user_id": "ou_xxxxx",
  "user_name": "显示名称"
}
```

### @ 所有人

```json
{
  "msg_type": "text",
  "content": {
    "text": "<at user_id=\"all\">所有人</at> 注意：明天有维护窗口"
  }
}
```

### 关键规则

1. **永远不要硬编码 chat_id** — 必须实时查询
2. **user_id 格式** — 机器人用 `ou_` 开头的 open_id，用户用 `ou_` 开头的 user_id
3. **@ all** — 需要群管理员权限
4. **消息发送前验证** — 确认 chat_id 和 user_id 都是当前会话的
