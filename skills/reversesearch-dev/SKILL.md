---
name: reversesearch-dev
description: reversesearch Dev Agent 工作流程 - 通过 Cursor CLI 完成代码审计、技术方案设计、代码实现
---

# reversesearch Dev Agent 工作流程

## 项目信息
- **项目路径**: `/Users/apple/work/tc-flight-int-reversesearch`
- **任务仓库路径**: `/Users/apple/work/tc-flight-int-reversepromotion`（任务文件存储在此）
- **任务目录**: `hermes-tasks/REQ-XXX/tasks/TASK-XXX.md`
- **项目名称**: tc-flight-int-reversesearch

> **重要**: 任务文件存储在 reversepromotion 仓库的 `hermes-tasks/` 目录下，不在 reversesearch 仓库内。
> **⚠️ 任务文件在 `hermes` 分支上，不是 `master`！** 查找任务文件前必须先 checkout 到 `hermes` 分支：
> ```bash
> cd /Users/apple/work/tc-flight-int-reversepromotion
> git checkout hermes  # 或 git checkout -b hermes origin/hermes
> ```
> 如果本地没有 `hermes` 分支，用 `git ls-tree -r origin/hermes --name-only | grep "TASK-"` 远程查看。

## ⚠️ 技术文档存放规则（强制！）

**技术文档必须放在对应项目的 `docs/` 目录下，禁止放在其他位置！**

### 文档路径规范

| 文档类型 | 路径格式 |
|---------|---------|
| 设计文档 | `docs/designs/TASK-XXX-design.md` |
| 审计报告 | `docs/audits/TASK-XXX-audit.md` |
| 技术方案 | `docs/solutions/TASK-XXX-solution.md` |

### 示例

```bash
# ✅ 正确：放在项目 docs 目录下
/Users/apple/work/tc-flight-int-reversesearch/docs/designs/TASK-006-design.md

# ❌ 错误：放在 /tmp 或其他本地目录
/tmp/design-TASK-006.md
/Users/apple/Desktop/design.md
```

### 创建目录

首次存放文档时，如果目录不存在需要创建：

```bash
mkdir -p /Users/apple/work/tc-flight-int-reversesearch/docs/designs
mkdir -p /Users/apple/work/tc-flight-int-reversesearch/docs/audits
mkdir -p /Users/apple/work/tc-flight-int-reversesearch/docs/solutions
```

### ⚠️ 设计文档同步到 reversepromotion 远端（必须！）

**设计文档确认前，必须同步到 tc-flight-int-reversepromotion 仓库的远端！**

原因：任务文件存储在 reversepromotion 仓库，设计文档需要团队可访问。

#### 同步流程

```bash
# 1. 进入 reversepromotion 仓库
cd /Users/apple/work/tc-flight-int-reversepromotion

# 2. 创建 docs/designs 目录（如不存在）
mkdir -p docs/designs

# 3. 复制设计文档
cp /Users/apple/work/tc-flight-int-reversesearch/docs/designs/design-TASK-XXX.md docs/designs/

# 4. 创建新分支（master 是受保护分支，不能直接推送！）
git checkout -b TASK-XXX_design_sync

# 5. 提交并推送
git add docs/designs/design-TASK-XXX.md
git commit -m "docs(TASK-XXX): 同步技术设计方案"
git push origin TASK-XXX_design_sync
```

#### ⚠️ Pitfall: reversepromotion 的 master 分支是受保护的

**绝对不能直接推送到 master！** 必须创建 feature 分支，然后通过 Merge Request 合并。

```bash
# ❌ 错误：直接推送到 master（会被 GitLab 拒绝）
git push origin master  # pre-receive hook declined

# ✅ 正确：推送到新分支
git checkout -b TASK-XXX_design_sync
git push origin TASK-XXX_design_sync
```

推送成功后，GitLab 会返回 Merge Request 创建链接，通知团队成员。

## 参考资料
- [reversesearch 项目架构参考](references/reversesearch-architecture.md) - 项目结构、RPC 配置、客户端实现模式
- [reverseauxiliary 集成模式](references/reverseauxiliary-integration.md) - Dubbo 配置、客户端模式、可用方法列表
- [飞书通知发送流程](references/feishu-notification.md) - 飞书 API 发送通知的备用方案
- [新增数据源实现模式](references/new-datasource-pattern.md) - Engine Source 架构、TW 实现示例
- [常用类包路径参考](references/package-paths.md) - 实际验证的 Java 包路径
- [Cursor CLI 委托模式](references/cursor-cli-delegation.md) - 代码审计、技术方案设计、代码实现全部通过 Cursor CLI 完成
- [Token 消耗查询](references/token-tracking.md) - 通过 state.db 查询 cron job token 使用量
- [校验逻辑实现模式](references/validation-pattern.md) - 婴儿旅客校验示例
- [代码审核常见模式](references/code-review-patterns.md) - 共享航班判断统一、枚举值null防御
- [dev-done 后完整流程](references/dev-done-workflow.md) - code-reviewing → cr-reviewing → testing 流程详情
- [单元测试 Mockito 模式](references/unit-test-mockito-patterns.md) - 反射测试私有方法、DTO 构造、常见陷阱
- [changecore 邮寄发票领域知识](references/changecore-invoice-domain.md) - ChangeInvoiceVO 字段、facade 层缺口
- [changecore-facade DTO 结构](references/changecore-facade-dto-structure.md) - model.psi vs response.query 两个 ChangeInfoDTO 的区别
- [单元测试私有方法模式](references/unit-test-private-methods.md) - JUnit 5 + Reflection 测试 private 方法模板

## ⚠️ @ 交互模式（2026-06-08 新流程）

**⚠️ 详见 `feishu-bot-mention` 技能获取最新的 @ 格式和 open_id！**
**⚠️ @ 人类用户（如项目负责人）前必须查询群成员列表，详见 `feishu-user-mention` 技能！**

**不再使用 cron job 轮询，改为飞书 @ 交互触发 Agent。**

### 流程

```
Manager 创建任务 → @ Dev Agent
Dev Agent 收到 @ → 认领 → Cursor CLI 代码审计 + 技术方案设计 → @ 项目负责人确认 → Cursor CLI 代码实现 → @ Manager + @ 代码审核助手
代码审核助手 收到 @ → 代码审核 → 审核通过 @ Manager + @ 改签搜索测试
改签搜索测试 收到 @ → 测试 → @ Manager + @ 项目负责人
失败 → 改签搜索测试 @ Dev Agent → Cursor CLI 修复 → @ 代码审核助手
```

### 触发方式

| 事件 | 触发方式 | 说明 |
|------|----------|------|
| 任务创建 | Manager @ Dev Agent | Manager 创建任务后直接 @ Dev |
| 设计完成 | Dev @ 项目负责人 | 等待确认 |
| 开发完成 | Dev @ Manager + @ 代码审核助手 | 通知 Manager 和代码审核助手 |
| 审核通过 | 代码审核助手 @ Manager + @ 改签搜索测试 | 通知测试 |
| 测试失败 | Test @ Dev Agent | 打回修复 |
| 测试完成 | Test @ Manager + @ 项目负责人 | 通知确认 |

### Agent 响应 @ 的逻辑

- 收到 @ 时，检查消息内容是否包含任务ID
- 如果包含任务ID，读取任务文件并认领
- 完成任务后，@ 下一个 Agent
- 使用自己 bot 的身份发送消息

### 通知方式

使用 `lark-cli` 发送 @ 消息（详见下方"飞书通知"章节）：
- 短消息：`--msg-type post` + zh_cn JSON
- 长消息（含 markdown）：`--text`

**群内机器人 open_id（@ 时直接使用）：**

| 机器人名称 | open_id |
|-----------|---------|
| 退改航manager | ou_f2d589556428f147b6c1d31a50d93a3d |
| 改签核心开发 | ou_b57a12a362e8c22e45884f10b96978af |
| 改签核心测试 | ou_396ed718a30720845e0b28bcc24337a1 |
| 改签搜索开发 | ou_b5c2236b558563fdd534ab8d1743a28c |
| 改签搜索测试 | ou_a046991c55781257d9c15105b6dce248 |
| 代码审核助手 | ou_5bef2b7e0871bd75e47971357ad6b666 |

**⚠️ 人类用户必须使用 union_id（on_ 开头），不能用 open_id（ou_ 开头）！open_id 对不同机器人是不一样的，union_id 是全局唯一的。**

**项目相关人类 union_id（@ 时使用）：**

| 名称 | union_id | 角色 | 说明 |
|------|----------|------|------|
| 李明俊 | on_66d0c445449e1b1fd43e9d2390f4a4af | reversesearch 负责人 | 设计确认、测试确认时 @ |
| 吴斌（飞书用户7657WP） | on_3dc2083dca647dd00ea9ac863babd488 | 群主 | 需求相关 @ |
| 印亚勇 | on_bd88ee1eea152657b096a28092d1ce56 | changecore 负责人 | 跨模块依赖时 @ |
| 孙玉坤 | on_b8a05aedb828d2f3ebb6a18069b9122b | - | - |
| 钱佳乐的 | on_1e78ddfb7fa8d339eb0a5014400d7b7a | - | - |

**@ 人类用户示例：**
```bash
# @ 李明俊 确认设计
lark-cli im +messages-send --chat-id "$CHAT_ID" \
  --content '{"zh_cn":{"title":"","content":[[{"tag":"at","user_id":"on_66d0c445449e1b1fd43e9d2390f4a4af"},{"tag":"text","text":" 设计方案已完成，请确认"}]]}}' \
  --msg-type post --as bot
```

**获取群内机器人 open_id：**

**⚠️ chat_id 必须动态查询，绝对不要硬编码！**
- 机器人可能在多个群，用错 chat_id 会导致"窜群"
- 必须从当前会话上下文获取实际群ID
- 使用 `lark-cli im chat.list` 查询机器人所在的群组列表，获取目标群的 chat_id

```bash
# 先查询群组列表，获取 chat_id
lark-cli im chat.list
# 然后用获取到的 chat_id 查询群内机器人
lark-cli im chat.members bots --params '{"chat_id":"'$CHAT_ID'"}'
```

**⚠️ 禁止使用硬编码 chat_id（如 oc_679c37d616217fa4350272e332a0dc64）！**
每次发消息前必须确认：chat_id 来自当前会话上下文或动态查询结果。

## ⚠️ 任务状态管理（强制检查点）

**状态更新是硬性门禁，每个节点必须先更新状态再执行下一步！**

### 状态流转顺序（2026-06-08 @ 交互模式）

```
created → dev-designing → dev-reviewing → dev-confirmed → dev-coding → dev-done → code-reviewing → cr-reviewing → testing → test-reviewing → test-done
                                                          ↓                                                        ↓
                                                    测试失败 → dev-fixing → dev-done（循环）              cr-reviewing 驳回 → dev-fixing → dev-done
```

### 状态说明

| 状态 | 说明 | 负责人 |
|------|------|--------|
| `created` | 新创建，等待 Dev 认领（Manager @ Dev 后） | Dev Agent |
| `dev-designing` | 设计中（Cursor CLI 代码审计 + 技术方案设计） | Dev Agent |
| `dev-reviewing` | 设计审核中，等待项目负责人确认 | 项目负责人 |
| `dev-confirmed` | 设计已确认 | Dev Agent |
| `dev-coding` | 开发中（Cursor CLI 代码实现） | Dev Agent |
| `dev-done` | 开发完成（Dev @ 代码审核助手） | - |
| `code-reviewing` | 代码审核中（代码审核助手审核） | 代码审核助手 |
| `cr-reviewing` | 交叉审核中（代码审核通过后 @ 吴斌） | 吴斌 |
| `dev-fixing` | 测试失败，打回 Dev 修复（Test @ Dev） | Dev Agent |
| `dev-waiting` | 串行模式，等待依赖方完成 | - |
| `testing` | 测试中 | 改签搜索测试 |
| `test-reviewing` | 测试完成，等待项目负责人确认 | 项目负责人 |
| `test-done` | 测试确认通过 | - |
| `done` | 需求完成（Manager 推导） | - |

### ⚠️ 已废弃状态（2026-06-08）

以下状态不再使用：
- `pm-analyzing` → 移除（无 PM Agent）
- `pm-tech-reviewing` → 移除（无 PM Agent）
- `pm-confirmed` → 移除（无 PM Agent）
- `dev-confirm` → 移除（合并到 dev-done → testing 直接流转）
- `dev-implementing` → 移除（被 `dev-coding` 替代）

**⚠️ 完整状态列表（14个）**：`created`, `dev-designing`, `dev-reviewing`, `dev-confirmed`, `dev-coding`, `dev-done`, `code-reviewing`, `cr-reviewing`, `dev-fixing`, `dev-waiting`, `testing`, `test-reviewing`, `test-done`, `done`

### 更新方式

**⚠️ task_manager.py 可能有路径问题（见 P64），推荐手动更新。**

**手动更新流程（推荐）**：
```bash
cd /Users/apple/work/tc-flight-int-reversepromotion
git checkout hermes  # 确保在 hermes 分支

TASK_FILE="hermes-tasks/REQ-XXX/tasks/TASK-XXX.md"

# 1. 更新 status 字段
sed -i '' 's/^status: 旧状态$/status: 新状态/' "$TASK_FILE"

# 2. 追加状态记录表行（如果表已存在）
# 在 "## 状态记录" 表格末尾追加：| 时间 | 操作人 | 动作 | 说明 |

# 3. 提交并推送
git add "$TASK_FILE" && git commit -m "chore(TASK-XXX): 状态变更 旧→新" && git push origin hermes
```

**⚠️ 如果 git push 被拒绝（远程有新提交），用 merge 而非 rebase**：
```bash
git pull origin hermes --no-rebase  # 解决冲突后 git add + git commit
git push origin hermes
```

### 可用命令

| 命令 | 说明 |
|------|------|
| `$TM list [--status STATUS] [--project PROJECT]` | 列出任务 |
| `$TM show TASK-ID` | 查看任务详情 |
| `$TM create --title "标题" --projects "project1" --priority high` | 创建任务 |
| `$TM transition TASK-ID --to STATUS` | 更新状态 |
| `$TM submit-design TASK-ID --project PROJECT --reviewer REVIEWER [--file /path/to/design.md]` | 提交设计 |
| `$TM submit-test TASK-ID --result pass\|fail [--file /path/to/report.md]` | 提交测试 |
| `$TM mark-dev-done TASK-ID --project PROJECT` | 标记开发完成 |
| `$TM notify TASK-xxx --summary "摘要"` | 生成通知 JSON |

**⚠️ 脚本不支持 `--parent`、`--req` 参数**，父子任务需手动创建文件。

### 状态记录表（必须同步更新！）

在任务文件的 `## 状态记录` 表格中追加新行：`| 时间 | 操作人 | 动作 | 说明 |`

### ⚠️ 关键规则

| 规则 | 说明 |
|------|------|
| **先更新状态再做事** | 设计完成 → 先更新为 dev-reviewing → 再发通知 |
| **确认后立即更新** | 收到确认 → 先更新为 dev-confirmed → 再开始实现 |
| **完成后立即更新** | 代码推送 → 先更新为 dev-done → 再通知消费方 |
| **状态+记录+推送三件套** | 更新状态 → 更新记录表 → git commit+push，缺一不可 |

## 设计反馈处理 — 只改文档不实现

用户指出设计问题时：**更新设计文档 → 推远程 → 通知确认 → 停。等待。**

用户说"设计方案确认通过"才是实现的触发信号。在此之前不能做任何实现相关的事。

## Cursor CLI 全流程（代码审计 + 技术方案设计 + 代码实现）

### 核心原则

**代码审计、技术方案设计、代码实现全部通过 Cursor CLI 完成**，Dev Agent 只负责任务协调和状态管理。

### 为什么用 Cursor CLI
- Cursor Agent 有更强的上下文理解能力，可以利用 Cursor IDE 的索引
- 支持交互模式，用户可以通过 tmux attach 实时查看和干预
- 代码审计和技术方案设计也能利用 Cursor 的代码分析能力
- 统一工具链，减少切换成本

### 三种模式

| 模式 | 命令 | 适用场景 |
|------|------|----------|
| **One-shot** | `cursor agent --trust "prompt"` | 简单任务，无需用户交互 |
| **Interactive** | `cursor agent`（tmux 会话） | 复杂任务，需要用户审批 |
| **Hermes 委托** | `delegate_task` + `terminal` | Agent 自动化调用 |

### 流程概览

```
1. Dev Agent 收到 @ → 认领任务
2. 创建 tmux 会话 → 启动 Cursor Agent（交互模式）
3. 发送代码审计指令 → Cursor 分析现有代码
4. 发送技术方案设计指令 → Cursor 生成设计文档
5. @ 项目负责人确认设计
6. 确认后 → 发送代码实现指令 → Cursor 编写代码
7. 验证代码 → git commit + push
8. @ Manager + @ 代码审核助手
```

### 代码审计流程（tmux 交互会话）

```bash
# 0. 设置环境变量
export CURSOR_API_KEY="your_key"

# 1. 创建 tmux 会话，启动 Cursor Agent 交互模式
SESSION_NAME="cursor-TASK-XXX"
tmux new-session -d -s "$SESSION_NAME" -c "/Users/apple/work/tc-flight-int-reversesearch" \
  "export CURSOR_API_KEY='$CURSOR_API_KEY' && cursor agent; exec bash"

# ⚠️ 必须等待 15 秒以上！
sleep 15

# 2. 验证 Cursor Agent 已启动
tmux capture-pane -t "$SESSION_NAME" -p | head -10

# 3. 写审计指令到临时文件
cat > /tmp/cursor-audit.txt << 'TASK'
请对以下代码进行审计：
1. 分析 XXXServiceImpl.java 的实现逻辑
2. 检查异常处理是否完善
3. 检查是否有潜在的 NPE 风险
4. 列出需要修改的代码位置和改进建议

文件路径：app/biz/src/main/java/com/ly/flight/intl/reversesearch/biz/service/impl/XXXServiceImpl.java
TASK

# 4. 通过 tmux send-keys 发送
tmux send-keys -t "$SESSION_NAME" "$(cat /tmp/cursor-audit.txt)" Enter
```

### 技术方案设计流程

```bash
# 在同一个 tmux 会话中继续发送设计指令
cat > /tmp/cursor-design.txt << 'TASK'
基于代码审计结果，请设计技术方案：
1. 需求背景：XXX
2. 改动范围：列出需要新增/修改的文件
3. 实现方案：详细的设计思路
4. 接口设计：新增/修改的接口签名
5. 异常处理策略
6. 单元测试计划

请将设计文档写入 /tmp/design-TASK-XXX.md
TASK

tmux send-keys -t "$SESSION_NAME" "$(cat /tmp/cursor-design.txt)" Enter
```

### 代码实现流程

```bash
# 设计确认后，在同一个 tmux 会话中发送实现指令
cat > /tmp/cursor-implement.txt << 'TASK'
技术方案已确认，请实现代码：
1. 按照设计方案实现 XXX 功能
2. 遵循项目现有代码风格
3. 新增单元测试
4. 确保编译通过

修改文件列表：
- app/biz/src/main/java/.../XXXServiceImpl.java（修改）
- app/biz/src/main/java/.../XXXValidator.java（新增）
- app/biz/src/test/java/.../XXXServiceImplTest.java（新增）
TASK

tmux send-keys -t "$SESSION_NAME" "$(cat /tmp/cursor-implement.txt)" Enter
```

### ⚠️ 必须通知用户会话 ID

**创建会话后，必须立刻告诉用户会话名称，让用户可以接入控制台查看 Cursor Agent 交互！**

通知格式：
```
tmux 会话已创建：cursor-TASK-XXX
接入命令：tmux attach -t cursor-TASK-XXX
退出（detach）：Ctrl+B 然后按 D
日志查看：tail -f /tmp/cursor-TASK-XXX.log
```

### 用户接入

```bash
tmux attach -t cursor-TASK-XXX
# 退出（detach）用 Ctrl+B 然后按 D
```

### Cursor CLI 认证验证

```bash
# 验证 API Key 是否有效
export CURSOR_API_KEY="your_key"
cursor agent "hi" 2>&1 | head -3
# 如果看到 "API key is invalid" → key 已失效，需要用户更新
```

### 何时可以自己操作
- ✅ 读取代码、搜索文件名、代码验证、设计文档、状态管理、飞书通知、tmux 会话管理
- ❌ 代码审计、技术方案设计、代码实现（必须通过 Cursor CLI）

### 降级方案

仅在 Cursor CLI 确实不可用时（如 API Key 失效且无法获取），可使用 Hermes 内置工具（`delegate_task`、`patch`、`write_file`）完成。降级仍需遵循代码审计、测试验证、commit 规范。

**⚠️ 降级方案是例外，不是常态。** 正常情况下必须用 Cursor CLI。

## 任务状态处理指南

### 状态分类与处理方式

| 状态 | 分类 | 处理方式 |
|------|------|----------|
| `created` | 待处理 | Manager @ Dev 后认领 + Cursor CLI 代码审计 |
| `dev-designing` | 进行中 | Cursor CLI 代码审计 + 技术方案设计 |
| `dev-reviewing` | 等待确认 | @ 项目负责人确认 |
| `dev-confirmed` | 等待实现 | 改为 `dev-coding`（Cursor CLI 代码实现） |
| `dev-coding` | 开发中 | Cursor CLI 代码实现 |
| `dev-done` | 开发完成 | @ Manager + @ 代码审核助手 |
| `dev-fixing` | 修复中 | 读取测试报告，Cursor CLI 修复代码 |
| `testing` | 测试中 | 等待代码审核助手/改签搜索测试完成 |
| `test-reviewing` | 测试确认 | 等待项目负责人确认 |
| `test-done` | 终态 | 执行巡检流程 |
| `done` | 需求完成 | 无需操作 |

### 终态任务处理（巡检流程）

当任务处于 `test-done` 或 `done` 状态时，**不做代码实现**，但应执行以下巡检流程：

1. **验证代码位置** - checkout 到 feature 分支，确认代码已提交
2. **检查合并状态** - `git log --oneline master..TASK-XXX` 确认是否已合并到 master
3. **更新状态记录表** - 在任务文件中追加巡检报告记录
4. **git commit + push** - 提交状态记录更新
5. **发送飞书通知** - 通知负责人巡检结果和后续步骤

> ⚠️ `dev-done` 是中间状态（开发完成，等待测试），不是终态。终态是 `test-done` 和 `done`。

### 代码验证要点

对于已完成的任务，验证以下内容：
- 代码是否已提交到 feature 分支
- 提交记录是否包含任务 ID
- 变更文件数量是否与设计文档一致
- 测试报告是否通过

## 工作流硬性规则

### 0. 绝对不能跳过状态，必须按当前状态走流程（硬性规则！）

**教训来源**：2026-06-16，收到 "jar开发完成 你可以继续开发" 通知后，直接跳到代码实现，违反流程。

- **从 `dev-waiting` 继续时，必须进入 `dev-designing`，不能直接跳到 `dev-coding`**
- **每个状态都有对应的职责，必须完成当前状态的职责才能进入下一状态**
- **收到上游通知时，只意味着依赖已就绪，不代表可以直接写代码**

**⚠️ 正确理解通知话术（容易误解！）**：

| 通知话术 | 错误理解 | 正确理解 |
|---------|---------|---------|
| "继续开发" | ❌ 直接开始写代码 | ✅ 继续开发**流程**（从当前状态进入下一状态） |
| "jar开发完成" | ❌ 可以直接实现 | ✅ 上游依赖已就绪，可以开始**设计流程** |
| "你可以继续开发了" | ❌ 跳过设计直接写代码 | ✅ 从 `dev-waiting` 转入 `dev-designing` |

**收到通知后的第一步永远是：确认当前状态 → 走该状态对应的流程 → 不能跳过**

**状态流转顺序（不可跳过）**：
```
dev-waiting → dev-designing → dev-reviewing → dev-confirmed → dev-coding → dev-done
```

**从 `dev-waiting` 继续的正确流程**：
1. 更新依赖版本 + 编译验证
2. 状态改为 `dev-designing`
3. Cursor CLI 代码审计 + 技术方案设计
4. 设计完成后，状态改为 `dev-reviewing`，@ 项目负责人确认
5. 确认通过后，状态改为 `dev-confirmed` → `dev-coding`
6. 代码实现完成后，状态改为 `dev-done`，@ 代码审核助手

### 1. 代码审计、技术方案设计、代码实现必须通过 Cursor CLI
- 禁止直接用 `write_file`/`patch` 写 Java 代码（降级方案除外）
- 代码审计必须通过 Cursor CLI 分析现有代码
- 技术方案设计必须通过 Cursor CLI 生成设计文档
- 代码实现必须通过 Cursor CLI 完成
- 必须用 tmux 会话运行 Cursor Agent 交互模式，用户 `tmux attach` 接入
- 必须用 `tmux send-keys` 发任务

### 2. 设计文档必须先更新再确认
- 用户反馈设计问题 → 先更新设计文档 → 推远程 → 通知确认 → 等确认

### 3. 禁止跳过确认直接实现
- 即使方案看起来很简单，也必须等用户确认

### 4. 任务状态必须完整更新
- 每次状态变更都要更新 status + 状态记录表 + git commit push

### 5. 接口提供方用 SNAPSHOT 版本
- 不要直接打 RELEASE 包

### 6. 设计文档必须包含使用说明
- Maven 坐标、使用示例、字段说明表、注意事项

## 分支规范

分次需求必须新建分支开发，不要在 master 上直接改动。

```bash
git checkout master && git pull origin master
git checkout -b TASK-XXX_简短描述
```

⚠️ **不要用 `feature/` 前缀！** 远程仓库如果已存在 `feature` 分支，`feature/TASK-XXX` 会导致 ref 冲突无法推送。使用 `TASK-XXX_描述` 格式（下划线连接）。

## 任务查找

```bash
# ⚠️ 任务文件在 hermes 分支上，不是 master！先切换分支
cd /Users/apple/work/tc-flight-int-reversepromotion
git checkout hermes  # 或 git checkout -b hermes origin/hermes

# 方式1：使用 task_manager.py（⚠️ 路径可能硬编码了其他用户，见 P64）
$TM list --project tc-flight-int-reversesearch

# 方式2：使用 find（推荐，主方案）
find hermes-tasks -name "TASK-*.md" -type f -exec grep -l "^project: tc-flight-int-reversesearch$" {} \;

# 方式3：远程查看（不切换分支）
git ls-tree -r origin/hermes --name-only | grep "TASK-"
```

## 环境配置（重要！）

tmux 和 lark-cli 都在 `/usr/local/bin/` 下，但默认 PATH 不包含。使用前必须设置：

```bash
export PATH="/usr/local/bin:/usr/local/Cellar/node@20/20.20.0/bin:$PATH"
```

验证命令：
```bash
tmux -V  # tmux 3.6b
lark-cli --version  # lark-cli version 1.0.45
cursor --version  # Cursor CLI version
```

## 飞书通知

Target: `feishu:$CHAT_ID`（chat_id 必须通过 `lark-cli im chat.list` 动态获取，不要硬编码）

### lark-cli 初始化（首次使用必须执行）

```bash
export PATH="/usr/local/bin:/usr/local/Cellar/node@20/20.20.0/bin:$PATH"
lark-cli config bind --source hermes --identity bot-only
```

**⚠️ 绑定后才能使用 lark-cli 发送消息，否则会报 `not_configured` 错误。**

### @ 格式

**推荐方案**：
- **短消息（< 500字）**：用 `--msg-type post` + zh_cn JSON，最可靠
- **长消息（含表格、代码块）**：用 `--text`，自动包装为 post 格式，避免 JSON 转义问题

### 重复 @ 机制

**如果负责人没有回复，继续 @ 直到确认！**

需要重复 @ 的状态：
- `dev-reviewing`：等待项目负责人确认设计
- `test-reviewing`：等待项目负责人确认测试

### 设计文档发送规范

**设计完成后，必须将完整设计概要直接发到群里**，不能只发文件路径引用。

消息内容应包含：
1. 需求概述（一句话）
2. 改动范围表格（文件名 + 操作 + 说明）
3. 新增错误码列表
4. 异常处理策略
5. 工时估算
6. 完整设计文档路径（作为补充参考）

## 代码审计原则

1. **Cursor CLI 审计**: 通过 Cursor Agent 分析现有代码，生成审计报告
2. **先审计后实现**: 必须先阅读相关源码，理解现有架构
3. **最小改动**: 只修改必要的文件，避免大范围重构
4. **保持一致性**: 遵循项目现有的代码风格和架构模式
5. **代码实现使用 Cursor CLI**: 代码审计、技术方案设计、代码实现全部通过 Cursor CLI 完成

## 依赖版本更新流程（TASK-RB 类型任务）

当收到 reverseBase 或其他跨模块依赖的版本更新通知时，按以下流程操作：

### 触发场景
- 退改航 Dev Agent 发送 "TASK-RB 依赖通知"
- reverseBase/changecore 发布新 SNAPSHOT 版本
- 消息中包含新版本号和枚举/类定义说明

### 更新步骤

```bash
# 1. 找到 reversesearch 项目 pom.xml
cd /Users/apple/work/tc-flight-int-reversesearch

# 2. 查看当前依赖版本
grep "reversebase.version" pom.xml
# 输出示例: <reversebase.version>1.9.5.91.RELEASE</reversebase.version>

# 3. 使用 patch 工具更新版本号（不要用 sed）
# 将 reversebase.version 从旧版本更新为新版本

# 4. 验证编译通过
/Users/apple/tool/maven/apache-maven-3.9.6/bin/mvn compile -q

# 5. 通知相关方
# - @ 改签搜索开发（ou_b5c2236b558563fdd534ab8d1743a28c）确认 TASK-004 完成
# - @ 改签核心开发（ou_b57a12a362e8c22e45884f10b96978af）提醒更新 changecore
```

### 通知模板

```json
{
  "zh_cn": {
    "title": "reverseBase 依赖更新完成",
    "content": [[
      {"tag": "at", "user_id": "ou_b5c2236b558563fdd534ab8d1743a28c"},
      {"tag": "text", "text": " TASK-XXX reversesearch 项目 reverseBase 依赖版本已更新为 X.X.X-SNAPSHOT，编译验证通过。请确认。"}
    ]]
  }
}
```

### ⚠️ 注意事项
- 只更新 pom.xml 中的版本属性，不要修改其他内容
- 编译验证必须通过后再发通知
- 如果编译失败，检查新版本的枚举/类是否有 breaking change
- 不需要创建 feature 分支，直接在当前分支更新即可

## 跨模块依赖编译流程（重要！）

当需要在 reversebase 或 changecore 中新增类/枚举时，必须按以下顺序操作：

```bash
# 1. 修改 reversebase
cd /Users/apple/work/tc-flight-int-reversebase
find . -name "pom.xml" -type f -exec sed -i '' 's/旧版本/新版本/g' {} \;
export JAVA_HOME=$(/usr/libexec/java_home -v 1.8 2>/dev/null)
/Users/apple/tool/maven/apache-maven-3.9.6/bin/mvn install -DskipTests

# 2. 修改 changecore
cd /Users/apple/work/tc-flight-int-changecore
/Users/apple/tool/maven/apache-maven-3.9.6/bin/mvn install -pl app/model -DskipTests

# 3. 最后编译 reversesearch
cd /Users/apple/work/tc-flight-int-reversesearch
/Users/apple/tool/maven/apache-maven-3.9.6/bin/mvn compile -pl app/integration,app/biz -am -DskipTests
```

## 方法签名验证

调用外部方法前，必须验证方法签名：

```bash
grep -A5 "方法名" /path/to/SourceFile.java | head -10
javap -p /path/to/ClassName.class | grep 方法名
```

## ⚠️ 禁止使用 Kanban 工具

**本项目使用 git-task 工作流，绝对不要使用 kanban_* 工具！**

## ⚠️ 文件编辑工具陷阱（2026-06-15 发现）

### P61. patch 工具报告 success 但未实际写入文件
**严重程度：🔴 高**

`patch` 工具可能返回 `"success": true` 并生成 diff 输出，但**文件实际未被修改**。这是间歇性问题，可能与文件读取缓存有关。

**症状**：
- patch 返回 success + diff
- `git diff` 显示无变更
- `read_file` 显示旧内容

**解决方案**：
1. **编辑后必须验证**：用 `git diff --stat` 确认文件实际变更
2. **降级方案**：用 `terminal` + `python3 -c` 直接读写文件：
```bash
python3 -c "
with open('path/to/File.java', 'r') as f:
    content = f.read()
content = content.replace('old', 'new')
with open('path/to/File.java', 'w') as f:
    f.write(content)
"
```
3. **不要信任 patch 的 success 返回值**，必须验证

### P62. hermes_tools read_file 返回带行号前缀的内容
**严重程度：🟡 中**

`from hermes_tools import read_file` 返回的内容每行带行号前缀：`"   148|        actual content"`，不能直接用于字符串匹配/替换。

**解决方案**：
- 用 `terminal` + `cat` 或 `python3 open()` 读取原始文件内容
- 或用 `read_file` 后 strip 行号前缀再使用

## 常见陷阱

| 错误做法 | 正确做法 |
|---------|---------|
| 用 `write_file`/`patch` 自己写 Java 代码 | 用 Cursor CLI 完成代码审计、技术方案设计、代码实现 |
| 用 kanban_* 工具查找/管理任务 | 用 task_manager.py 或文件系统扫描 |
| 用 `screen -X stuff` 发中文（乱码） | 用 `tmux send-keys`（原生 Unicode） |
| Cursor Agent 401 Unauthorized | 设置 `CURSOR_API_KEY` 环境变量 |
| 信任 `target/` 的 .class 文件 | 只看 `src/` 目录下的 .java 源文件 |
| 用户反馈后直接实现 | 更新文档 → 推远程 → 等确认 → 再实现 |
| 对 `test-done` 任务做代码实现 | 终态任务只做巡检（验证+记录+通知），不做代码实现 |
| `dev-confirmed` 后直接开始写代码 | 先改为 `dev-coding` 再开始实现 |
| 手动更新状态后不推送 | 更新状态 → 记录表 → git commit+push 三件套 |
| lark-cli 未绑定直接使用 | 先执行 `lark-cli config bind --source hermes --identity bot-only` |
| 用 `feature/` 前缀创建分支 | 远程已有 `feature` 分支会导致 ref 冲突，用 `TASK-XXX_描述` 格式 |

## 关键 Pitfalls

### P42. task_manager.py list 命令可能找不到子任务
- **正确做法**: 文件系统扫描是主方案：`find hermes-tasks -name "TASK-*.md" -type f`

### P46. 邮寄发票判断：用 mailState 属性，且仅过滤 MAILED 状态
- `mailState` 为 null → 无邮寄发票 → 不过滤
- `mailState` 为 `NO_MAIL`/`WAIT_MAIL` → 未实际邮寄 → 不过滤
- `mailState` 为 `MAILED` (code=2) → 已邮寄 → 过滤

### P50. JUnit 4 测试在 JUnit 5 平台上静默不运行
- 所有新测试必须使用 JUnit 5（Jupiter）注解

### P55. feature/ 前缀导致远程 ref 冲突无法推送
- 使用 `TASK-XXX_描述` 格式（下划线连接，不带 `feature/` 前缀）

### P56. Cursor Agent 自动 git add 提交无关文件
- 完成后检查 `git diff HEAD~1 --stat`，如果包含无关文件：
  ```bash
  git reset --soft HEAD~1
  git reset HEAD -- 无关文件路径
  git commit -m "正确的提交信息"
  ```

### P57. Mockito + 反射测试私有方法的常见陷阱
- 枚举值不存在 → grep 源码确认实际枚举名
- DTO 字段类型不匹配 → 检查 setter 参数类型
- `@Resource` 注入的 Bean 为 null → 添加 `@Mock` 对应依赖
- 使用 `@MockitoSettings(strictness = Strictness.LENIENT)` 避免 UnnecessaryStubbing

### P58. lark-cli 不可用时的备用方案（2026-06-12 发现）
**严重程度：🟡 中**

`lark-cli` 可能未安装或不在 PATH 中。有两种备用方案：

**方案 A：使用 send_message 工具（推荐）**
```python
send_message(target="feishu", message="消息内容")
```
send_message 会自动使用当前会话的 chat_id，无需手动获取。

**方案 B：直接调用 Feishu API**
需要 `curl -k`（跳过 SSL 证书验证），因为内网环境有自签名证书。

```bash
# 获取 token
source ~/.hermes/profiles/reversesearchdev/.env
TOKEN=$(curl -sk "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
  -H "Content-Type: application/json" \
  -d "{\"app_id\":\"$FEISHU_APP_ID\",\"app_secret\":\"$FEISHU_APP_SECRET\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['tenant_access_token'])")

# 发送消息（content 必须是 JSON 字符串，不是嵌套 JSON）
curl -sk "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=chat_id" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"receive_id\":\"$CHAT_ID\",\"msg_type\":\"post\",\"content\":\"$CONTENT_JSON_STRING\"}"
```

⚠️ `content` 字段的值必须是 **JSON 字符串**（`json.dumps(content, ensure_ascii=False)`），不能直接嵌套 JSON 对象，否则报 `230001 invalid message content`。

### P60. 未确认设计就直接实现代码（2026-06-13 发现）
**严重程度：🔴 高**

技术方案设计完成后，必须先 @ 项目负责人确认，确认通过后才能进行代码实现。即使代码已经通过 Cursor CLI 实现完成，如果跳过了确认环节，也是流程错误。

```
❌ 错误流程：设计完成 → 直接代码实现 → 通知审核
✅ 正确流程：设计完成 → @ 项目负责人确认 → 确认通过 → 代码实现 → 通知审核
```

**教训**：2026-06-13 TASK-004 开发时，设计完成后直接进行了代码实现，被用户（吴斌）指出流程错误。

### P63. 发送通知时使用了硬编码的 chat_id（2026-06-16 发现）
**严重程度：🔴 高**

发送飞书通知时，必须使用**当前会话上下文的 chat_id**，不能使用硬编码的群ID。

**症状**：
- 消息发送到了错误的群
- 用户在 A 群通知，但消息出现在 B 群

**错误做法**：
```bash
# ❌ 硬编码 chat_id
lark-cli im +messages-send --chat-id "oc_679c37d616217fa4350272e332a0dc64" ...
```

**正确做法**：
```bash
# ✅ 从当前会话上下文获取 chat_id
# 方式1：从 send_message 工具自动获取
send_message(target="feishu:$CHAT_ID", message="...")

# 方式2：用 lark-cli 动态查询
lark-cli im chat.list  # 先列出机器人所在群，确认群名与当前会话一致
```

**关键规则**：
- 机器人可能在多个群，用错 chat_id 会导致"窜群"
- 每次发消息前必须确认：chat_id 来自当前会话上下文或动态查询结果
- 用户当前所在的群 chat_id 可以从会话上下文中获取（如 `oc_26451a5c8065350656dbb0ee155789b9`）

### P64. task_manager.py 路径硬编码了其他用户的 workspace（2026-06-16 发现）
**严重程度：🟡 中**

`/Users/apple/.hermes/profiles/changecoredev/skills/git-task-coordination/templates/task_manager.py` 中的 `REPO_PATH` 硬编码为 `/Users/yyy/workspace/project/tc-flight-int-reversepromotion`，不是 `/Users/apple/work/tc-flight-int-reversepromotion`。

**解决方案**：
- 直接用 git 命令手动更新任务文件，不要依赖 task_manager.py
- 或修改 task_manager.py 中的 `REPO_PATH` 为正确的路径

### P65. git pull --rebase 在 dumb terminal 中失败（EDITOR 未设置）（2026-06-16 发现）
**严重程度：🟡 中**

`git pull --rebase` 在 Hermes terminal 环境中会报 `Terminal is dumb, but EDITOR unset` 错误，因为 rebase 需要打开编辑器处理 commit message，但 Hermes 的 terminal 没有设置 EDITOR 环境变量。

**解决方案**：
```bash
# ❌ 错误：使用 rebase
git pull origin hermes --rebase  # Terminal is dumb, but EDITOR unset

# ✅ 正确：使用 merge
git pull origin hermes --no-rebase
```

如果 merge 产生冲突，手动解决后 `git add` + `git commit` 即可（不需要 `git rebase --continue`）。

### P59. reversepromotion 仓库 master 分支受保护（2026-06-12 发现）
**严重程度：🟡 中**

`tc-flight-int-reversepromotion` 仓库的 master 分支是受保护的，**不能直接推送**。设计文档同步到该仓库时，必须创建 feature 分支。

```bash
# ❌ 错误：直接推送到 master
git push origin master  # pre-receive hook declined

# ✅ 正确：创建新分支后推送
git checkout -b TASK-XXX_design_sync
git push origin TASK-XXX_design_sync
```

推送成功后 GitLab 会返回 Merge Request 创建链接，需要通知团队成员合并。

## Maven 构建必须使用 Java 8
```bash
# ⚠️ Java 8 JDK 路径可能不存在，先验证
export JAVA_HOME=$(/usr/libexec/java_home -v 1.8 2>/dev/null)
# Maven 路径（2026-06-12 更新）：
/Users/apple/tool/maven/apache-maven-3.9.6/bin/mvn compile -pl app/biz -am -DskipTests
```

⚠️ **已知编译问题**：`SpeedChangeFlightFilter.java` 引用了 `com.sun.javafx.binding` 包，在非 Oracle JDK 环境下会报错。这是预存在问题，与 TASK-004 无关。

⚠️ **Java 版本**：当前系统默认 Java 17（Microsoft OpenJDK），项目要求 Java 8。如果 Java 8 JDK 不存在，编译会在 `-source 8` 模式下运行但可能有兼容性警告。
