# lark-cli Python 封装脚本

> 安装路径：`~/.local/bin/lark-cli`
> 创建日期：2026-06-16
> 原因：npm `lark-cli` 包是空壳 placeholder，无 CLI 功能

## 安装步骤

```bash
mkdir -p ~/.local/bin
# 将下方脚本写入 ~/.local/bin/lark-cli
chmod +x ~/.local/bin/lark-cli
# 确保 PATH 包含 ~/.local/bin（已在 .zshrc/.bash_profile 中配置）
```

## 脚本内容

```python
#!/usr/bin/env python3
"""lark-cli - Feishu/Lark CLI tool for sending messages"""
import json, os, sys, ssl, urllib.request

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

def load_env():
    env_file = os.path.expanduser("~/.hermes/profiles/reversesearchdev/.env")
    env_vars = {}
    if os.path.exists(env_file):
        with open(env_file) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    k, v = line.split('=', 1)
                    env_vars[k.strip()] = v.strip().strip('"').strip("'")
    return env_vars

def get_token(app_id, app_secret):
    req = urllib.request.Request(
        'https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal',
        data=json.dumps({"app_id": app_id, "app_secret": app_secret}).encode(),
        headers={"Content-Type": "application/json"}
    )
    resp = json.loads(urllib.request.urlopen(req, context=ctx).read())
    return resp.get('tenant_access_token', '')

def send_message(token, chat_id, content, msg_type="post"):
    body = {
        "receive_id": chat_id,
        "msg_type": msg_type,
        "content": content if isinstance(content, str) else json.dumps(content, ensure_ascii=False)
    }
    req = urllib.request.Request(
        'https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=chat_id',
        data=json.dumps(body, ensure_ascii=False).encode('utf-8'),
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {token}"}
    )
    return json.loads(urllib.request.urlopen(req, context=ctx).read())

def list_chats(token):
    req = urllib.request.Request(
        'https://open.feishu.cn/open-apis/im/v1/chats?page_size=50',
        headers={"Authorization": f"Bearer {token}"}
    )
    return json.loads(urllib.request.urlopen(req, context=ctx).read())

def main():
    env = load_env()
    app_id, app_secret = env.get('FEISHU_APP_ID',''), env.get('FEISHU_APP_SECRET','')
    if not app_id or not app_secret:
        print("Error: FEISHU credentials not found"); sys.exit(1)
    token = get_token(app_id, app_secret)

    if len(sys.argv) < 2:
        print("Usage: lark-cli <send|post|list-chats|token|im +messages-send ...>")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "token":
        print(token)
    elif cmd == "list-chats":
        resp = list_chats(token)
        if resp.get('code') == 0:
            for item in resp.get('data',{}).get('items',[]):
                print(f"{item.get('chat_id')}  {item.get('name','(unnamed)')}")
    elif cmd == "send":
        chat_id, message = sys.argv[2], ' '.join(sys.argv[3:])
        content = json.dumps({"zh_cn":{"title":"","content":[[{"tag":"text","text":message}]]}}, ensure_ascii=False)
        resp = send_message(token, chat_id, content, "post")
        print(f"code={resp.get('code')}, msg={resp.get('msg')}")
    elif cmd == "im" and len(sys.argv)>2 and sys.argv[2]=="+messages-send":
        args = sys.argv[3:]; chat_id = content = None; msg_type = "post"; i = 0
        while i < len(args):
            if args[i]=="--chat-id" and i+1<len(args): chat_id = args[i+1]; i+=2
            elif args[i]=="--content" and i+1<len(args): content = args[i+1]; i+=2
            elif args[i]=="--msg-type" and i+1<len(args): msg_type = args[i+1]; i+=2
            elif args[i]=="--text" and i+1<len(args):
                content = json.dumps({"zh_cn":{"title":"","content":[[{"tag":"text","text":args[i+1]}]]}}, ensure_ascii=False)
                msg_type = "post"; i+=2
            elif args[i]=="--as": i+=2
            else: i+=1
        if not chat_id or not content:
            print("Error: --chat-id and --content required"); sys.exit(1)
        resp = send_message(token, chat_id, content, msg_type)
        print(f"code={resp.get('code')}, msg={resp.get('msg')}")
    else:
        print(f"Unknown command: {cmd}"); sys.exit(1)

if __name__ == "__main__":
    main()
```

## 依赖

无外部依赖，仅使用 Python 标准库（json, os, sys, ssl, urllib）。

## 注意事项

- 飞书 API 使用 HTTPS，内网环境有自签名证书，所以 `ssl.CERT_NONE`
- `content` 字段必须是 JSON 字符串，不能嵌套 JSON 对象（否则报 230001 错误）
- 凭据从 `~/.hermes/profiles/reversesearchdev/.env` 读取
