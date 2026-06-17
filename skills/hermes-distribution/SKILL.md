---
name: hermes-distribution
description: |
  Hermes agent distribution 全生命周期：初始化仓库、安装、发布、拉取、定时同步。
  提供：五场景路由、scripts/ 可执行脚本、references/ 分场景操作说明。
  适用：新建/发布/更新 agent distribution、profile install、12h 双向同步。
  不适用：业务代码开发（非 distribution 文件）。
---

# Hermes Distribution

一个 skill 覆盖 distribution 全生命周期。先识别用户意图，**只读一个** reference，再执行对应脚本。

## 场景路由

| 场景 | 用户说法（示例） | Reference | 脚本 |
|------|------------------|-----------|------|
| **init** | 新建 agent、初始化 distribution | [init.md](references/init.md) | `scripts/init-distribution.sh` |
| **install** | 安装 Git 地址、首次装 profile | [install.md](references/install.md) | `hermes profile install` |
| **publish** | 发布、推送最新配置 | [publish.md](references/publish.md) | `scripts/publish.sh` |
| **update** | 拉取、更新远端配置 | [update.md](references/update.md) | `scripts/update.sh` |
| **cron** | 12h 自动同步、定时 publish/pull | [cron-sync.md](references/cron-sync.md) | `scripts/setup-cron.sh` |

## 关键规则

1. **先路由再执行**：一次对话只走一个场景，不混 init 与 install
2. **工作目录**：脚本从 profile 根目录调用，路径为 `skills/hermes-distribution/scripts/`
3. **配置来源**：统一读 `distribution.yaml`（`source:`、`publish:` 块），**无** `publish.config`
4. **cron 入口**：`profile/scripts/agent-sync-watchdog.sh`（Hermes 限制）；逻辑在 skill 内
5. **称呼**：用「其他开发者」，不用「队友」
6. **init vs install**：init = 创建者可 push；install = 消费者只 pull

## 快速命令

```bash
cd ~/.hermes/profiles/<name>

# 发布
skills/hermes-distribution/scripts/publish.sh [REMOTE]

# 拉取
skills/hermes-distribution/scripts/update.sh

# 注册 12h cron
skills/hermes-distribution/scripts/setup-cron.sh
```

## 详细文档

- 初始化脚手架 → [init.md](references/init.md)
- 其他开发者安装 → [install.md](references/install.md)
- 发布 → [publish.md](references/publish.md)
- 拉取与冲突 → [update.md](references/update.md)
- 定时同步 → [cron-sync.md](references/cron-sync.md)
- `.env` 配置 → [env-setup.md](references/env-setup.md)
- Git URL 格式 → [source-formats.md](references/source-formats.md)
