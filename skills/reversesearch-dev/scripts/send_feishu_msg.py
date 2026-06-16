#!/usr/bin/env python3
"""
发送飞书消息（@ 机器人或用户）的通用脚本。
当 lark-cli 不可用时使用此脚本。

用法:
    python3 scripts/send_feishu_msg.py --chat-id oc_xxx --user-id ou_xxx --title "标题" --text "消息内容"
    python3 scripts/send_feishu_msg.py --chat-id oc_xxx --user-id on_xxx --title "标题" --text "消息内容"  # @ 人类用户用 union_id

参数:
    --chat-id   群聊 ID（oc_ 开头）
    --user-id   要 @ 的用户/机器人 open_id（ou_ 开头）或 union_id（on_ 开头）
    --title     消息标题
    --text      消息正文（支持 \n 换行）
    --env-file  .env 文件路径（默认 ~/.hermes/profiles/reversesearchdev/.env）
"""
import json
import os
import sys
import argparse
import urllib.request
import ssl


def get_env(env_file):
    env_vars = {}
    with open(env_file) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                k, v = line.split('=', 1)
                env_vars[k.strip()] = v.strip().strip('"').strip("'")
    return env_vars


def get_token(app_id, app_secret):
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    req = urllib.request.Request(
        'https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal',
        data=json.dumps({"app_id": app_id, "app_secret": app_secret}).encode(),
        headers={"Content-Type": "application/json"}
    )
    resp = json.loads(urllib.request.urlopen(req, context=ctx).read())
    return resp.get('tenant_access_token', '')


def send_post_message(token, chat_id, user_id, title, text):
    """发送 post 格式消息，支持 @ 用户"""
    content = {
        "zh_cn": {
            "title": title,
            "content": [[
                {"tag": "at", "user_id": user_id},
                {"tag": "text", "text": f" {text}"}
            ]]
        }
    }
    body = {
        "receive_id": chat_id,
        "msg_type": "post",
        "content": json.dumps(content, ensure_ascii=False)
    }
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    req = urllib.request.Request(
        'https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=chat_id',
        data=json.dumps(body, ensure_ascii=False).encode('utf-8'),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        }
    )
    resp = json.loads(urllib.request.urlopen(req, context=ctx).read())
    return resp


def main():
    parser = argparse.ArgumentParser(description='发送飞书消息')
    parser.add_argument('--chat-id', required=True, help='群聊 ID')
    parser.add_argument('--user-id', required=True, help='要 @ 的用户 ID')
    parser.add_argument('--title', required=True, help='消息标题')
    parser.add_argument('--text', required=True, help='消息正文')
    parser.add_argument('--env-file', default=os.path.expanduser('~/.hermes/profiles/reversesearchdev/.env'),
                        help='.env 文件路径')
    args = parser.parse_args()

    env = get_env(args.env_file)
    token = get_token(env['FEISHU_APP_ID'], env['FEISHU_APP_SECRET'])
    if not token:
        print("ERROR: Failed to get token", file=sys.stderr)
        sys.exit(1)

    resp = send_post_message(token, args.chat_id, args.user_id, args.title, args.text)
    print(f"code={resp.get('code')}, msg={resp.get('msg')}")
    if resp.get('code') == 0:
        print("消息发送成功！")
    else:
        sys.exit(1)


if __name__ == '__main__':
    main()
