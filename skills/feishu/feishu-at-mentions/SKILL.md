---
name: feishu-at-mentions
description: 在飞书群消息中 @ 其他用户或 bot
tags: [feishu, lark, at, mention]
triggers:
  - "需要在飞书消息中 @ 其他用户或 bot"
  - "飞书 @ 格式"
  - "mention other bots in feishu"
---

# 飞书 @ 提及技能

## 🚨 第一原则：禁止使用写死的群ID！

**所有发送消息的操作必须使用当前会话的实际 chat_id，绝对不能用技能里写死的 chat_id。**

飞书机器人可能同时在多个群里，用错 chat_id 会导致"窜群"——消息发到别的群去了。

### 获取当前群 ID 的方法

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

### ⚠️ 发送前必须确认
1. 列出机器人所在的所有群
2. 根据群名找到当前会话对应的 chat_id
3. 确认无误后再发送
4. **绝对不能凭记忆使用 chat_id，每次都必须实时查询**

---

## ⚠️ 核心要点

**`send_message` 的 `<at>` 标签只是纯文本，不会触发真正的 @ 提醒！必须用 `lark-cli` + JSON at 标签格式。**

## @ Bot vs @ 人类的 ID 区别

| 类型 | ID 前缀 | 是否唯一 | 来源 |
|------|---------|---------|------|
| **@ Bot（机器人）** | `ou_` (open_id) | ❌ 每个机器人不同 | 记录在 feishu-bot-mention skill |
| **@ 人类用户** | `on_` (union_id) | ✅ 全局唯一 | 实时查询群成员列表 |

**⚠️ @ 人类用户时必须使用 union_id（on_ 开头），不能用 open_id（ou_ 开头），因为 open_id 对不同机器人是不一样的！**

## 方案
使用 `lark-cli im +messages-send` 命令，`--msg-type post`，`--content JSON` 格式。

## 核心命令

```bash
# ⚠️ $CHAT_ID 必须通过上方方法实时查询，不能写死！
lark-cli im +messages-send --as bot \
  --chat-id "$CHAT_ID" \
  --content '<JSON>' \
  --msg-type post
```

## JSON 格式

```json
{
  "zh_cn": {
    "title": "",
    "content": [
      [
        {"tag": "at", "user_id": "ou_xxx"},
        {"tag": "at", "user_id": "ou_yyy"},
        {"tag": "text", "text": " 消息内容"}
      ]
    ]
  }
}
```

## 示例

```bash
# ⚠️ $CHAT_ID 必须实时查询！
lark-cli im +messages-send --as bot \
  --chat-id "$CHAT_ID" \
  --content '{"zh_cn":{"title":"","content":[[{"tag":"at","user_id":"ou_b5c2236b558563fdd534ab8d1743a28c"},{"tag":"text","text":" 你好！"}]]}}' \
  --msg-type post
```

## 已知机器人 open_id（仅供参考，以实际查询为准）

| 机器人 | open_id |
|--------|---------|
| 退改航manager | ou_f2d589556428f147b6c1d31a50d93a3d |
| 改签核心开发 | ou_b57a12a362e8c22e45884f10b96978af |
| 改签核心测试 | ou_396ed718a30720845e0b28bcc24337a1 |
| 改签搜索开发 | ou_b5c2236b558563fdd534ab8d1743a28c |
| 改签搜索测试 | ou_a046991c55781257d9c15105b6dce248 |
| 国际退改助手 | ou_a271cc999125c2f11cfc91d213c24d62 |

## 已知群 ID（仅供参考，发送前务必实时查询确认当前群）

| 群名 | chat_id | 用途 |
|------|---------|------|
| 国际退改飞书群 | oc_679c37d616217fa4350272e332a0dc64 | 主群（退改航需求对接） |
| REQ-特殊事件: 改签报价 | oc_0b51a94306edcfdf9774057bfec1feb6 | 特殊事件/改签报价群 |

## 项目负责人

**飞书用户7657WP = 吴斌（同一人，2026-06-11 确认）**

| 项目 | 角色 | 负责人 | union_id |
|------|------|--------|----------|
| changecore（改签核心） | 提供方 | 印亚勇 | on_bd88ee1eea152657b096a28092d1ce56 |
| reversesearch（改签搜索） | 消费方 | 李明俊 | on_66d0c445449e1b1fd43e9d2390f4a4af |

## ⚠️ 注意事项

1. **chat_id 必须实时查询，不能写死** — 避免窜群
2. `send_message` 工具的 `<at id=user_id></at>` 格式**不能**正确 @ 用户（只是纯文本）
3. 必须使用 `lark-cli` + `post` 消息类型
4. `title` 字段可以为空字符串
5. 多个 @ 放在同一个 content 数组元素中
6. `--content` 参数**不需要**外层的 `"post"` 键，直接是 `zh_cn` 对象
7. 设计确认、巡检报告等需要人类确认的通知，必须 @ 项目负责人，不是 @ 机器人
