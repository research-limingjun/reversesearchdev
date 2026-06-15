# Cursor CLI 代码审计 + 技术方案设计 + 代码实现委托模式

## 核心原则
**代码审计、技术方案设计、代码实现全部通过 Cursor CLI 完成**，Dev Agent 只负责任务协调和状态管理。

## 三种使用模式

### 模式1：tmux 交互会话（推荐，用户可交互）

适合需要用户审批、确认、或查看执行过程的任务。会在 Cursor IDE Sessions 面板中显示。

```bash
export CURSOR_API_KEY="your_key"

# 创建 tmux 会话
SESSION_NAME="cursor-TASK-XXX"
tmux new-session -d -s "$SESSION_NAME" -c "/Users/apple/work/tc-flight-int-reversesearch" \
  "export CURSOR_API_KEY='$CURSOR_API_KEY' && cursor agent; exec bash"

sleep 15
tmux capture-pane -t "$SESSION_NAME" -p | head -10
```

⚠️ **交互模式不要加 `--trust`**——会报错：`--trust can only be used with --print/headless mode`

### 模式2：One-shot（后台执行，无需用户交互）

适合简单任务，执行完自动退出。

```bash
export CURSOR_API_KEY="your_key"
cursor agent --trust "你的任务描述"
```

- `--trust` 自动批准工作区操作，**只能用于 one-shot / headless 模式**
- 不会在 Cursor IDE 中留下 session 记录

### 模式3：Hermes delegate_task 委托

适合 Agent 自动化调用，无需用户交互。

```python
delegate_task(
    goal="在 XXXServiceImpl.java 中新增 checkYYY() 方法",
    context="""
## 代码审计结果
审计发现需要新增 YYY 校验逻辑...

## 技术方案
1. 新增私有方法 checkYYY()
2. 在 validate() 入口处调用
3. 校验失败抛出 ValidateErrorException

## 修改文件
- app/biz/src/main/java/.../XXXServiceImpl.java

## 代码规范
- 私有方法必须声明 throws ValidateErrorException
- 使用 logger.error() 而不是 log.error()

项目路径：/Users/apple/work/tc-flight-int-reversesearch
""",
    toolsets=["terminal", "file"]
)
```

## 代码审计指令模板

```txt
请对以下代码进行审计：
1. 分析 XXXServiceImpl.java 的实现逻辑
2. 检查异常处理是否完善
3. 检查是否有潜在的 NPE 风险
4. 列出需要修改的代码位置和改进建议

文件路径：app/biz/src/main/java/com/ly/flight/intl/reversesearch/biz/service/impl/XXXServiceImpl.java
```

## 技术方案设计指令模板

```txt
基于代码审计结果，请设计技术方案：
1. 需求背景：XXX
2. 改动范围：列出需要新增/修改的文件
3. 实现方案：详细的设计思路
4. 接口设计：新增/修改的接口签名
5. 异常处理策略
6. 单元测试计划

请将设计文档写入 /tmp/design-TASK-XXX.md
```

## 代码实现指令模板

```txt
技术方案已确认，请实现代码：
1. 按照设计方案实现 XXX 功能
2. 遵循项目现有代码风格
3. 新增单元测试
4. 确保编译通过

修改文件列表：
- app/biz/src/main/java/.../XXXServiceImpl.java（修改）
- app/biz/src/main/java/.../XXXValidator.java（新增）
- app/biz/src/test/java/.../XXXServiceImplTest.java（新增）
```

## 常见错误
- ❌ 直接用 `write_file` 写 Java 代码（降级方案除外）
- ❌ 直接用 `patch` 修改实现文件（降级方案除外）
- ❌ 自己手写代码逻辑（降级方案除外）
- ✅ 委托给 Cursor CLI，让 AI 生成代码
- ✅ Cursor CLI 不可用时，用 `delegate_task` + `toolsets=["terminal", "file"]` 降级实现

## 降级方案：delegate_task（Cursor CLI 不可用时）

**触发条件**：Cursor API 返回 "Failed to reach the Cursor API" 或 API Key 过期。

**实现方式**：将实现拆分为多个小任务，通过 `delegate_task` 并行执行：
1. 先自己完成代码审计（read_file + search_files）
2. 准备详细的实现规范（包括完整代码片段、文件路径、import 列表）
3. 用 `delegate_task` 委托子 agent 创建/修改文件
4. 验证结果后 git commit + push

**优势**：子 agent 有独立上下文，不会污染主会话。
**劣势**：需要更详细的上下文传递，子 agent 可能不了解项目特定约定。

## 何时可以自己操作
- 读取代码（`read_file`、`search_files`）
- 技术设计文档（`.md` 文件）
- 任务状态管理（`task_manager.py`）
- 飞书通知（`send_message`）
- tmux 会话管理

## Pitfalls

### P1. `--trust` 不能用于交互模式
- ✅ 交互模式：`cursor agent`（不加任何参数）
- ✅ One-shot 模式：`cursor agent --trust "prompt"`（加 `--trust` + 提示词）
- ❌ 错误：`cursor agent --trust`（`--trust` 但没有提示词 → 报错）

### P2. API Key 验证
```bash
export CURSOR_API_KEY="your_key"
cursor agent "hi" 2>&1 | head -3
# 如果看到 "API key is invalid" → key 已失效，需要用户更新
```

### P3. Cursor Agent 自动 git add 提交无关文件
- 完成后检查 `git diff HEAD~1 --stat`
- 如果包含无关文件：`git reset --soft HEAD~1` + 选择性 unstage

### P4. tmux 交互模式 + send-keys 不可靠（2026-06-11 发现）
**严重程度：🔴 高**

通过 `tmux send-keys` 向交互模式的 Cursor Agent 发送指令时，Agent 会显示 `[Pasted text #1 +N lines]` 但**不会实际处理指令**。等待数分钟后仍无进展。

**症状**：
```
  → [Pasted text #1 +35 lines]
  Composer 2.5 Fast
  ~/work/tc-flight-int-reversesearch · openspec
```
Agent 停在此状态，不执行任何操作。

**正确做法**：对于自动化任务（代码审计、技术方案设计），**必须使用 one-shot 模式**：
```bash
export CURSOR_API_KEY="your_key"
cd /path/to/project
cursor agent --trust "你的任务描述" 2>&1
```

**何时用交互模式**：仅当用户需要手动审批、干预、或实时查看执行过程时（用户自己 `tmux attach` 操作）。

### P5. API Key 存储位置
Cursor CLI API Key 不在 `~/.cursor/cli-config.json` 中。查找方式：
```bash
grep -r "crsr_" ~/.hermes/profiles/*/sessions/*.json 2>/dev/null | head -5
```
或在 `~/.hermes/profiles/*/state.db` 中搜索。
