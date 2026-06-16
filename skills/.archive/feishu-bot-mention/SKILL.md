---
name: feishu-bot-mention
description: "飞书群内机器人互相@的技能 - 包含所有机器人的open_id和@方法"
version: 1.3.0
last_verified: 2026-06-10
metadata:
  hermes:
    tags: [feishu, bot, mention, collaboration]
---

# 飞书群机器人互@技能

## 🚨 第一原则：禁止使用写死的群ID！

**所有发送消息的操作必须使用当前会话的实际 chat_id，绝对不能用技能里写死的 chat_id。**

飞书机器人可能同时在多个群里，用错 chat_id 会导致"窜群"——消息发到别的群去了。

### 获取当前群 ID 的方法

**方法1：从终端命令获取（推荐）**
```bash
# 第一步：获取 token
source ~/.hermes/profiles/reversesearchdev/.env 2>/dev/null
TOKEN=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
  -H "Content-Type: application/json" \
  -d "{\"app_id\":\"$FEISHU_APP_ID\",\"app_secret\":\"$FEISHU_APP_SECRET\"}" | python3 -c "import sys,json; print(json.load(sys.stdin)['tenant_access_token'])")

# 第二步：列出机器人所在的所有群，根据群名找到当前群的 chat_id
curl -s "https://open.feishu.cn/open-apis/im/v1/chats?page_size=50" \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for item in data['data'].get('items', []):
    print(f\"{item['chat_id']}  {item.get('name', '(unnamed)')}\")
"

# 第三步：确认群名与当前会话一致后，用该 chat_id 发送消息
```

**方法2：从 Hermes 会话上下文推断**
- 当前会话的 `source` 字段会标明来源平台和群名
- 结合方法1的群列表，匹配群名找到对应 chat_id

### ⚠️ 发送前必须确认
1. 列出机器人所在的所有群
2. 根据群名找到当前会话对应的 chat_id
3. 确认无误后再发送
4. **绝对不能凭记忆使用 chat_id，每次都必须实时查询**

---

## 群内机器人列表

**⚠️ 群内实际有 9 个 BOT（2026-06-10 确认），以下仅记录已知的 6 个，另有 3 个未知 BOT 待确认。**

| 机器人名称 | open_id | 角色 |
|-----------|---------|------|
| 退改航manager | ou_f2d589556428f147b6c1d31a50d93a3d | Manager - 需求分析拆解和任务调度 |
| 改签核心开发 | ou_b57a12a362e8c22e45884f10b96978af | Dev Agent - changecore项目开发 |
| 改签核心测试 | ou_396ed718a30720845e0b28bcc24337a1 | Test Agent - changecore项目测试 |
| 改签搜索开发 | ou_b5c2236b558563fdd534ab8d1743a28c | Dev Agent - reversesearch项目开发 |
| 改签搜索测试 | ou_a046991c55781257d9c15105b6dce248 | Test Agent - reversesearch项目测试 |
| 国际退改助手 | ou_a271cc999125c2f11cfc91d213c24d62 | 辅助机器人 |

### 已知的未知 BOT（待确认 open_id）
- 国际机票退改航团队负责人BOT（2026-06-10 用户询问）

### 已知群 ID（仅供参考，发送前务必实时查询确认当前群）

| 群名 | chat_id | 用途 |
|------|---------|------|
| 国际退改飞书群 | oc_679c37d616217fa4350272e332a0dc64 | 主群（退改航需求对接） |
| REQ-特殊事件: 改签报价 | oc_0b51a94306edcfdf9774057bfec1feb6 | 特殊事件/改签报价群 |

---

## 发送 @ 消息的方法

### 方式1：lark-cli（推荐首选）

```bash
# ⚠️ $CHAT_ID 必须通过上方"获取当前群 ID 的方法"实时查询得到，不能写死！
lark-cli im +messages-send --chat-id "$CHAT_ID" \
  --content '{"zh_cn": {"title": "", "content": [[{"tag": "at", "user_id": "ou_xxxxxx"}, {"tag": "text", "text": " 消息内容"}]]}}' \
  --msg-type post --as bot
```

### 方式2：curl 调用飞书 API（lark-cli 不可用时）

```bash
# ⚠️ $CHAT_ID 必须实时查询，不能写死！
curl -s -X POST "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=chat_id" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"receive_id\": \"$CHAT_ID\",
    \"msg_type\": \"post\",
    \"content\": \"{\\\"zh_cn\\\":{\\\"title\\\":\\\"\\\",\\\"content\\\":[[{\\\"tag\\\":\\\"at\\\",\\\"user_id\\\":\\\"ou_xxxxxx\\\"},{\\\"tag\\\":\\\"text\\\",\\\"text\\\":\\\" 消息内容\\\"}]]}}\"
  }"
```

### 示例：@ 改签核心开发

```bash
lark-cli im +messages-send --chat-id "$CHAT_ID" \
  --content '{"zh_cn": {"title": "", "content": [[{"tag": "at", "user_id": "ou_b57a12a362e8c22e45884f10b96978af"}, {"tag": "text", "text": " 请处理任务 TASK-001"}]]}}' \
  --msg-type post --as bot
```

### 同时 @ 多个机器人

```bash
lark-cli im +messages-send --chat-id "$CHAT_ID" \
  --content '{"zh_cn": {"title": "", "content": [[{"tag": "at", "user_id": "ou_b57a12a362e8c22e45884f10b96978af"}, {"tag": "text", "text": " "}, {"tag": "at", "user_id": "ou_396ed718a30720845e0b28bcc24337a1"}, {"tag": "text", "text": " 任务已完成，请测试"}]]}}' \
  --msg-type post --as bot
```

---

## 协作流程

1. **Manager → PM/Dev**: 创建任务后 @ 对应的开发机器人
2. **Dev → Test**: 开发完成后 @ 对应的测试机器人
3. **Test → Manager**: 测试完成后 @ Manager 确认
4. **Manager → 项目经理**: 测试完成后 @ 项目经理确认

## Manager 发送测试完成通知示例（2026-06-08 新增）

**当 Test Agent @ Manager 报告测试完成时，Manager 需要 @ 项目经理确认：**

```bash
# ⚠️ $CHAT_ID 必须实时查询！
lark-cli im +messages-send --chat-id "$CHAT_ID" \
  --content '{"zh_cn":{"title":"TASK-xxx 测试完成通知","content":[[{"tag":"at","user_id":"ou_xxx","user_name":"李明俊"},{"tag":"text","text":" TASK-xxx 测试已完成，请确认测试结果。"}],[{"tag":"text","text":""}],[{"tag":"text","text":"【测试结果汇总】"}],[{"tag":"text","text":"✅ Code Review 通过"}],[{"tag":"text","text":"✅ 单元测试通过"}],[{"tag":"text","text":"✅ 编译验证通过"}],[{"tag":"text","text":"✅ 依赖状态就绪"}],[{"tag":"text","text":""}],[{"tag":"text","text":"【下一步行动】"}],[{"tag":"text","text":"1. 请确认测试结果，如无问题可标记为 done"}],[{"tag":"text","text":"2. 测试通过，建议合入主分支"}]]}}' \
  --msg-type post --as bot
```

---

## 前提条件

**⚠️ 每个机器人 profile 都需要配置 `FEISHU_ALLOW_BOTS=mentions`！**

```bash
# 在每个机器人 profile 的 .env 中添加
echo "FEISHU_ALLOW_BOTS=mentions" >> ~/.hermes/profiles/<bot-profile>/.env

# 重启 gateway 使配置生效
hermes gateway restart --profile <bot-profile>
```

**不需要 `im:message.send_as_user` 权限** — 配置 `FEISHU_ALLOW_BOTS=mentions` 后 bot 身份就能 @ 其他 bot。

---

## Pitfalls（踩坑记录）

### Pitfall #1: 绝对不能用写死的 chat_id（2026-06-10 教训）

**严重程度：🔴 高**

机器人可能同时在多个群里（如"国际退改飞书群"和"REQ-特殊事件: 改签报价"），用写死的 chat_id 会把消息发到错误的群（"窜群"）。

**正确做法**：
1. 每次发消息前，先用 API 列出机器人所在的所有群
2. 根据群名找到当前会话对应的 chat_id
3. 用该 chat_id 发送

**错误做法**：
- ❌ 直接用技能文档里的 chat_id
- ❌ 凭记忆使用 chat_id
- ❌ 假设 chat_id 不会变

### Pitfall #2: send_message 工具的 @ 格式兼容性（2026-06-08 验证）

**实测结论**：`send_message` 发送 `<at user_id="ou_xxx">` 标签在 **post 格式下可以被飞书正确解析**（生成 mentions 字段，触发蓝色高亮+推送）。

**2026-06-08 全量验证结果**（4/4 通过）：

| Bot | 使用方式 | mentions 解析 | 结果 |
|-----|---------|--------------|------|
| 改签核心开发 | lark-cli post | ✅ | 通过 |
| 改签搜索开发 | lark-cli post | ✅ | 通过 |
| 改签核心测试 | send_message + `<at>` | ✅ | 通过 |
| 改签搜索测试 | lark-cli post + send_message | ✅ | 通过 |

**可用格式**（两种都能触发 @）：
1. **lark-cli + `--content` JSON + `--msg-type post`** — 标准格式，推荐首选
2. **send_message + `<at user_id="ou_xxx">名字</at>`** — 也能被飞书解析（post 格式下）

**绝对不能用**：
- ❌ `--msg-type text`（text 类型不解析 @ 标签）
- ❌ `--markdown '<at id=...>'`（markdown 模式不触发 @）

**建议**：统一用 lark-cli 以保证一致性，但 SOUL.md 中不需要禁止 send_message（它确实能工作）。

### Pitfall #3: 绝对不能用 --markdown 参数
`--markdown '<at id=...>'` 格式会被解析为 markdown 文本，@ 标签不会被解析为可点击的 @ 提醒。

### Pitfall #4: 绝对不能用 --msg-type text
`--content '{"text":"<at user_id=...>...</at>"}' --msg-type text` 也是错误的，text 类型不会解析 @ 标签。

### Pitfall #5: JSON 格式必须是 zh_cn 包裹，不是 post 包裹
错误：`{"post":{"zh_cn":...}}`
正确：`{"zh_cn":{"title":"","content":[[...]]}}`

### Pitfall #6: FEISHU_ALLOW_BOTS=mentions 必须在每个 bot 的 .env 中配置
Manager 的 .env 配置不会应用到其他 bot profile。每个 bot 都需要单独添加并重启 gateway。

### Pitfall #7: 区分 bot 和人类用户的 @（2026-06-08 教训）
用户说"@吴斌"时，先判断是 bot 还是人类。**不要凭记忆推测 open_id**，必须从群成员列表实时查询。
- **Bot**：有固定 open_id，记录在上方"群内机器人列表"表格中
- **人类**：需要执行 API 查询群成员列表获取 open_id
- 如果用户不在群内，需要先拉入群或告知用户

### Pitfall #8: Bots 可能用错误格式发送
测试发现 bots 读了 SOUL.md 后仍可能用 send_message 或 --markdown 发送。需要在 SOUL.md 中用**醒目格式**强调必须用 lark-cli + --content + --msg-type post。

### Pitfall #9: 飞书 API 不返回群内 BOT 成员（2026-06-10 发现）
飞书 API `/im/v1/chats/{chat_id}/members` **只返回人类成员，不返回 BOT 成员**。因此无法通过 API 枚举群内 BOT 列表。
- 群信息接口 `/im/v1/chats/{chat_id}` 返回的 `bot_count` 字段可查看 BOT 总数
- 要获取未知 BOT 的 open_id，只能：(1) 让该 BOT 自行报告；(2) 在飞书管理后台查看；(3) 问管理员

### Pitfall #10: lark-cli 不可用时的替代方案（2026-06-10 发现）
如果 `lark-cli` 命令不存在，**不要尝试 `npm install -g lark-cli`**——npm 上的 `lark-cli` 是一个空壳包（只有一个空的 index.js，没有任何功能）。直接用 curl 调用飞书 API（需要 app_id 和 app_secret）：
1. POST `/open-apis/auth/v3/tenant_access_token/internal` 获取 token
2. GET `/open-apis/im/v1/chats` 列出机器人所在的所有群（获取当前群 chat_id）
3. GET `/open-apis/im/v1/chats/{chat_id}` 获取群信息（含 bot_count）
4. GET `/open-apis/im/v1/chats/{chat_id}/members?page_size=100` 获取群人类成员列表

App 凭据在各 profile 的 `.env` 中：`FEISHU_APP_ID` 和 `FEISHU_APP_SECRET`。

---

## @ 人类用户（非 bot）

当需要 @ 人类用户（如吴斌、李明俊等）时，格式与 @ bot 相同，但需要先查到该用户的 open_id。

### 查找群内用户 open_id

```bash
# ⚠️ $CHAT_ID 必须实时查询！
lark-cli im chat.members get --params "{\"chat_id\":\"$CHAT_ID\"}" --page-all --format table
```

返回格式：
```
member_id                            member_id_type  name
ou_xxx                               open_id         吴斌
```

### @ 人类用户示例

```bash
lark-cli im +messages-send --chat-id "$CHAT_ID" \
  --content '{"zh_cn":{"title":"","content":[[{"tag":"at","user_id":"ou_xxx"},{"tag":"text","text":" 消息内容"}]]}}' \
  --msg-type post --as bot
```

**⚠️ 必须从群成员列表中获取 open_id，不能凭记忆或推测。** 用户的 open_id 格式是 `ou_` 开头的字符串。

---

## 群内已知人类成员（使用 union_id）

**⚠️ 人类用户统一使用 union_id（同一个人不会变），open_id 可能随租户变化。**
**⚠️ 以下列表可能过时，@ 人类用户前务必执行 API 查询获取最新成员列表。**

**飞书用户7657WP = 吴斌（同一人，2026-06-11 确认）**

### 国际退改飞书群（5人）— 2026-06-11 API 查询

| 名称 | union_id | 备注 |
|------|----------|------|
| 吴斌（飞书用户7657WP） | on_3dc2083dca647dd00ea9ac863babd488 | 群主 |
| 印亚勇 | on_bd88ee1eea152657b096a28092d1ce56 | changecore 负责人 |
| 李明俊 | on_66d0c445449e1b1fd43e9d2390f4a4af | reversesearch 负责人 |
| 孙玉坤 | on_b8a05aedb828d2f3ebb6a18069b9122b | |
| 钱佳乐的 | on_1e78ddfb7fa8d339eb0a5014400d7b7a | |

### REQ-特殊事件: 改签报价群（3人）— 2026-06-11 API 查询

| 名称 | union_id | 备注 |
|------|----------|------|
| 吴斌（飞书用户7657WP） | on_3dc2083dca647dd00ea9ac863babd488 | |
| 印亚勇 | on_bd88ee1eea152657b096a28092d1ce56 | |
| 李明俊 | on_66d0c445449e1b1fd43e9d2390f4a4af | |

### @ 人类用户的方法

**⚠️ @ 人类用户时 `user_id` 填 union_id，飞书支持 union_id 作为 at 的 user_id。**

```bash
# 获取群成员 union_id
curl -s "https://open.feishu.cn/open-apis/im/v1/chats/$CHAT_ID/members?page_size=100&member_id_type=union_id" \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for item in data['data'].get('items', []):
    print(f\"{item['member_id']}  {item['name']}\")
"

# @ 吴斌 示例
lark-cli im +messages-send --chat-id "$CHAT_ID" \
  --content '{"zh_cn":{"title":"","content":[[{"tag":"at","user_id":"on_3dc2083dca647dd00ea9ac863babd488"},{"tag":"text","text":" 消息内容"}]]}}' \
  --msg-type post --as bot
```

**⚠️ 必须从群成员列表中获取 union_id，不能凭记忆或推测。**

---

## 注意事项

1. 必须使用 `--as bot` 参数（机器人身份发送）
2. 必须使用 `--msg-type post`（富文本格式）
3. @ 格式：`{"tag": "at", "user_id": "ou_xxxxxx"}`
4. **chat_id 必须实时查询，不能写死**
5. **每个机器人 profile 独立配置** — Manager 的 .env 不会应用到其他 profile
6. **修改 .env 后必须重启 gateway** — 否则配置不生效
7. **不需要 im:message.send_as_user 权限** — 配置 FEISHU_ALLOW_BOTS=mentions 后 bot 身份即可
8. **区分 bot 和人类用户** — 用户说"@某某"时，先确认是 bot 还是人类。bot 有固定 open_id 在上方表格；人类需要从群成员列表实时查询
