---
name: feishu-user-mention
description: "飞书群内@人类用户的技能 - 包含查找用户union_id的方法和@格式"
version: 1.0.0
last_verified: 2026-06-08
metadata:
  hermes:
    tags: [feishu, user, mention, collaboration]
---

# 🚨 最高优先级原则：禁止使用写死的群ID

**⚠️ 禁止使用写死的群 chat_id！必须实时查询当前群的 chat_id，否则会发生"窜群"（消息发到错误的群）！**

**正确做法：** 每次发送消息前，先执行查询命令获取当前正确的 chat_id，赋值给 `$CHAT_ID` 变量，然后在所有命令中使用 `$CHAT_ID`。

# 飞书群@人类用户技能

## 获取当前群的 chat_id（必须实时查询）

### 方法：列出所有可见群聊，按名称找到目标群

```bash
# 列出所有机器人可见的群聊（会显示 chat_id 和群名称）
lark-cli im chats list --format table
```

### 返回格式

```
chat_id                                name
oc_679c37d616217fa4350272e332a0dc64    国际退改飞书群
oc_0b51a94306edcfdf9774057bfec1feb6    REQ-特殊事件: 改签报价
```

### 正确用法：赋值给变量后使用

```bash
# 1. 查询并确认目标群的 chat_id
CHAT_ID="oc_xxxx"  # 从上方查询结果中复制目标群的 chat_id

# 2. 后续所有命令一律使用 $CHAT_ID
echo "$CHAT_ID"  # 确认变量值正确
```

**⚠️ 绝对不要在命令中直接写 oc_xxxxxx 形式的 chat_id，一律使用 $CHAT_ID 变量！**

## 与 @ Bot 的区别

| 类型 | 格式 | ID 来源 | ID 类型 |
|------|------|---------|---------|
| @ Bot | `{"tag":"at","user_id":"ou_xxx"}` | 固定，记录在 feishu-bot-mention | open_id |
| @ 人类 | `{"tag":"at","user_id":"on_xxx"}` | **实时查询群成员列表** | **union_id**（同一个人不会变） |

**⚠️ 人类用户统一使用 union_id（on_ 开头），不能用 open_id！open_id 可能随租户变化。**

## 已知人类成员（使用 union_id，仅供参考，@ 前务必重新查询）

**飞书用户7657WP = 吴斌（同一人，2026-06-11 确认）**

| 名称 | union_id | 角色 |
|------|----------|------|
| 吴斌（飞书用户7657WP） | on_3dc2083dca647dd00ea9ac863babd488 | 群主 |
| 印亚勇 | on_bd88ee1eea152657b096a28092d1ce56 | changecore 负责人 |
| 李明俊 | on_66d0c445449e1b1fd43e9d2390f4a4af | reversesearch 负责人 |
| 孙玉坤 | on_b8a05aedb828d2f3ebb6a18069b9122b | - |
| 钱佳乐的 | on_1e78ddfb7fa8d339eb0a5014400d7b7a | - |

**⚠️ 以上列表可能过时，@ 人类用户前务必执行查询命令获取最新成员列表。**

## 查找群内用户 union_id

### 命令

```bash
curl -s "https://open.feishu.cn/open-apis/im/v1/chats/$CHAT_ID/members?page_size=100&member_id_type=union_id" \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for item in data['data'].get('items', []):
    print(f\"{item['member_id']}  {item['name']}\")
"
```

### 返回格式

```
member_id                            name
on_3dc2083dca647dd00ea9ac863babd488  吴斌
on_bd88ee1eea152657b096a28092d1ce56  印亚勇
```

### 群 ID

**⚠️ 以下列表仅供参考，发送消息前务必实时查询确认正确的 chat_id！禁止直接使用表中的 chat_id！**

| 群名称 | chat_id |
|--------|---------|
| 国际退改飞书群 | oc_679c37d616217fa4350272e332a0dc64 |
| REQ-特殊事件: 改签报价 | oc_0b51a94306edcfdf9774057bfec1feb6 |

## @ 人类用户的正确格式

### 使用 lark-cli 发送 @ 消息

```bash
lark-cli im +messages-send --chat-id "$CHAT_ID" \
  --content '{"zh_cn":{"title":"","content":[[{"tag":"at","user_id":"ou_xxx"},{"tag":"text","text":" 消息内容"}]]}}' \
  --msg-type post --as bot
```

### 示例：@ 吴斌 确认需求拆解

```bash
# 使用吴斌的 union_id 直接发送
lark-cli im +messages-send --chat-id "$CHAT_ID" \
  --content '{"zh_cn":{"title":"","content":[[{"tag":"at","user_id":"on_3dc2083dca647dd00ea9ac863babd488"},{"tag":"text","text":" 📋 需求拆解确认\n\n需求: xxx\n涉及项目: xxx\n\n请确认拆解方案是否正确。"}]]}}' \
  --msg-type post --as bot
```

### 示例：@ 李明俊 通知任务完成

```bash
lark-cli im +messages-send --chat-id "$CHAT_ID" \
  --content '{"zh_cn":{"title":"","content":[[{"tag":"at","user_id":"on_66d0c445449e1b1fd43e9d2390f4a4af"},{"tag":"text","text":" ✅ 任务完成\n\n任务ID: TASK-xxx\n项目: reversesearch\n状态: test-done"}]]}}' \
  --msg-type post --as bot
```

## 常见使用场景

### 1. Manager @ 项目经理确认需求拆解

```
Manager 分析需求 → 查询项目经理 open_id → @ 项目经理确认 → 等待确认 → 创建任务
```

### 2. Dev Agent @ 项目负责人确认设计

```
Dev 完成设计 → 查询项目负责人 open_id → @ 项目负责人确认 → 等待确认 → 开始开发
```

### 3. Test Agent @ 项目负责人确认测试

```
Test 完成测试 → 查询项目负责人 open_id → @ 项目负责人确认 → 等待确认 → 标记完成
```

### 4. Agent @ Manager 同步状态

```
Agent 完成任务 → 查询 Manager open_id → @ Manager 通知完成
```

## Pitfalls（踩坑记录）

### Pitfall #1: 绝对不能凭记忆推测人类用户的 union_id

人类用户的 union_id 虽然比 open_id 稳定（同一个人不会变），但仍需确认用户身份。**每次 @ 人类用户前建议重新查询群成员列表确认。**

### Pitfall #2: 人类用户必须用 union_id（on_ 开头），不能用 open_id（ou_ 开头）

open_id 可能随租户变化，union_id 是跨租户稳定的。**飞书 at 标签支持 union_id 作为 user_id。**

### Pitfall #2: 用户可能不在群内

如果查询群成员列表后找不到目标用户，可能是因为：
1. 用户不在该群内
2. 用户名称拼写错误
3. 用户已退出群聊

**解决方案**：告知用户目标用户不在群内，需要先拉入群或确认正确的用户名称。

### Pitfall #3: 查询命令需要 user 身份

`lark-cli im chat.members get` 命令需要使用 `--as user` 参数（默认），而不是 `--as bot`。Bot 身份可能没有查询群成员的权限。

```bash
# 正确：使用 user 身份查询
lark-cli im chat.members get --params "{\"chat_id\":\"$CHAT_ID\"}" --page-all --format table

# 错误：使用 bot 身份查询（可能权限不足）
lark-cli im chat.members get --params "{\"chat_id\":\"$CHAT_ID\"}" --as bot
```

### Pitfall #4: 与 feishu-bot-mention 的区别

| 场景 | 使用技能 | open_id 来源 |
|------|---------|-------------|
| @ 其他 Bot | feishu-bot-mention | 固定，记录在技能中 |
| @ 人类用户 | feishu-user-mention | 实时查询群成员列表 |

**不要混淆两者！** Bot 的 open_id 是固定的，人类用户的 open_id 需要实时查询。

### Pitfall #5: 绝对不能使用写死的 chat_id（窜群问题）

**这是最常见的严重错误！** 如果在命令中直接写入硬编码的 chat_id（如 `oc_679c37d616217fa4350272e332a0dc64`），当目标群发生变化时，消息会被发送到错误的群（"窜群"），导致：
- 敏感信息泄露到不相关的群
- 目标群收不到消息，任务沟通中断
- 需要手动撤回错误消息，造成混乱

**正确做法：**
1. 每次发送消息前，先通过 `lark-cli im chats list` 查询并确认目标群的 chat_id
2. 将 chat_id 赋值给 `$CHAT_ID` 变量
3. 所有命令中一律使用 `$CHAT_ID`，禁止直接写 `oc_xxx`

```bash
# ❌ 错误：直接写死 chat_id
lark-cli im +messages-send --chat-id "oc_679c37d616217fa4350272e332a0dc64" ...

# ✅ 正确：先查询，再用变量
CHAT_ID="oc_xxxx"  # 从 lark-cli im chats list 查询结果中获取
lark-cli im +messages-send --chat-id "$CHAT_ID" ...
```

## 唯一正确的发送格式

```bash
lark-cli im +messages-send --chat-id "$CHAT_ID" \
  --content '{"zh_cn":{"title":"","content":[[{"tag":"at","user_id":"on_xxx"},{"tag":"text","text":" 消息内容"}]]}}' \
  --msg-type post --as bot
```

## 注意事项

1. **必须实时查询 chat_id** — 禁止使用写死的群ID，必须先查询并赋值给 `$CHAT_ID`
2. **人类用户使用 union_id** — `on_` 开头，同一个人不会变
3. **必须先查询 union_id** — 不能凭记忆推测
4. **必须使用 `--as bot`** — 机器人身份发送
5. **必须使用 `--msg-type post`** — 富文本格式
6. **@ 格式** — `{"tag": "at", "user_id": "on_xxxxxx"}`（注意是 on_ 不是 ou_）
