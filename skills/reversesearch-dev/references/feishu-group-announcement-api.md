# 飞书群公告更新 API

## 概述

群公告有两种格式，API 不兼容：
- **旧版 `doc`**：使用 `PATCH /open-apis/im/v1/chats/{chat_id}/announcement`
- **新版 `docx`**：使用 `POST /open-apis/docx/v1/chats/{chat_id}/announcement/blocks/{block_id}/children`

通过 `GET /open-apis/docx/v1/chats/{chat_id}/announcement` 获取 `announcement_type` 字段判断格式。

## 旧版 API（doc 格式）

### 端点
```
PATCH https://open.feishu.cn/open-apis/im/v1/chats/{chat_id}/announcement
```

### 请求格式
```json
{
    "revision": "0",
    "requests": ["<JSON字符串化的操作请求>"]
}
```

**关键**：`requests` 是 `string[]`，每个元素是 JSON 字符串化的操作请求对象（不是直接的对象！）。

### 支持的操作类型

| requestType | 状态 | 说明 |
|-------------|------|------|
| `InsertBlocksRequestType` | ✅ 可用 | 插入 blocks |
| `UpdateTitleRequestType` | ✅ 可用 | 更新标题 |
| `DeleteContentRangeRequestType` | ❌ 不支持 | 返回 `checkDeleteContentRange fail` |
| `ReplaceAllTextRequestType` | ❌ 不支持 | 返回 `invalid batch_update request type` |
| `UpdateParagraphStyleRequestType` | ❌ 不支持 | 返回 `invalid batch_update request type` |

### InsertBlocksRequestType 格式
```python
blocks_payload = {
    "blocks": [
        {
            "type": "paragraph",
            "paragraph": {
                "elements": [
                    {
                        "type": "textRun",
                        "textRun": {
                            "text": "显示文字",
                            "style": {"bold": True}  # 可选
                        }
                    }
                ],
                "style": {}
            }
        }
    ]
}

insert_request = {
    "requestType": "InsertBlocksRequestType",
    "insertBlocksRequest": {
        "payload": json.dumps(blocks_payload, ensure_ascii=False),
        "location": {"zoneId": "0", "index": 0, "endOfZone": True}
    }
}

body = {
    "revision": "0",  # "0" = 追加（不是覆盖！）
    "requests": [json.dumps(insert_request, ensure_ascii=False)]
}
```

### 超链接格式
```python
# URL 必须 encode
encoded_url = urllib.parse.quote(url, safe='')

element = {
    "type": "textRun",
    "textRun": {
        "text": "点击查看详情",
        "style": {"link": {"url": encoded_url}}
    }
}
```

### revision 语义
- `"0"`：追加到现有内容（不是覆盖！）
- 具体数字：基于该版本操作（但仍然追加）
- **没有覆盖/替换能力**，只能追加

### 完整示例：插入带超链接的内容

> ⚠️ **原则：chat_id 必须动态查询，不得硬编码。** 使用前应通过 `lark-cli im +chats-list` 或其他方式获取目标群组的 chat_id，赋值给 `$CHAT_ID` 变量。

```python
import json, urllib.request, urllib.parse

with open('/tmp/feishu_token.json') as f:
    token = json.load(f)['tenant_access_token']

chat_id = os.environ.get("CHAT_ID")  # 动态获取，不得硬编码
doc_url = "http://git.17usoft.com/flightint/tc-flight-int-reversepromotion/-/blob/hermes/hermes-tasks/REQ-003/tasks/TASK-005/dev-design-reversesearch.md"
encoded_url = urllib.parse.quote(doc_url, safe='')

title_req = {
    "requestType": "UpdateTitleRequestType",
    "updateTitleRequest": {
        "title": {"elements": [{"type": "textRun", "textRun": {"text": "标题文字", "style": {"bold": True}}}]}
    }
}

blocks_payload = {
    "blocks": [
        {
            "type": "paragraph",
            "paragraph": {
                "elements": [
                    {"type": "textRun", "textRun": {"text": "任务标题", "style": {}}}
                ],
                "style": {}
            }
        },
        {
            "type": "paragraph",
            "paragraph": {
                "elements": [
                    {"type": "textRun", "textRun": {
                        "text": "设计文档：dev-design-reversesearch.md",
                        "style": {"link": {"url": encoded_url}}
                    }}
                ],
                "style": {}
            }
        }
    ]
}

insert_req = {
    "requestType": "InsertBlocksRequestType",
    "insertBlocksRequest": {
        "payload": json.dumps(blocks_payload, ensure_ascii=False),
        "location": {"zoneId": "0", "index": 0, "endOfZone": True}
    }
}

body = {
    "revision": "0",
    "requests": [
        json.dumps(title_req, ensure_ascii=False),
        json.dumps(insert_req, ensure_ascii=False)
    ]
}

data = json.dumps(body, ensure_ascii=False).encode('utf-8')
req = urllib.request.Request(
    f'https://open.feishu.cn/open-apis/im/v1/chats/{chat_id}/announcement',
    data=data, method='PATCH',
    headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json; charset=utf-8'}
)
resp = urllib.request.urlopen(req)
result = json.loads(resp.read())
print(f"code={result['code']}, msg={result['msg']}")
```

## 新版 API（docx 格式）

### 创建块
```
POST https://open.feishu.cn/open-apis/docx/v1/chats/{chat_id}/announcement/blocks/{block_id}/children?revision_id=-1
```
- `block_id` 填 `chat_id` 表示根块
- 请求体：`{"children": [block_objects]}`
- block_type: 2=文本, 3=标题1, 12=无序列表 等

### 删除块
```
DELETE https://open.feishu.cn/open-apis/docx/v1/chats/{chat_id}/announcement/blocks/{block_id}/children/batch_delete?revision_id=-1
```
- 请求体：`{"start_index": 0, "end_index": N}`（左闭右开）

### 批量更新
```
PATCH https://open.feishu.cn/open-apis/docx/v1/chats/{chat_id}/announcement/blocks/batch_update
```

## 权限要求
- `im:chat` 或 `im:chat.announcement:write_only`
- 机器人必须在群组内
- 内部群操作者和群组必须在同一租户

## 已知限制（2026-06-05 验证）
- 旧版公告（`doc`）无法通过 API 升级到新版（`docx`）
- 飞书客户端编辑公告不会自动触发格式迁移
- 旧版 API 只支持插入和改标题，不支持删除/替换
- 重复插入会导致重复内容，需要先 GET 检查已有内容
