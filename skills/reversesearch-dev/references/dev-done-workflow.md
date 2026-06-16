# dev-done 后的完整流程

## 状态流

```
dev-done → code-reviewing → cr-reviewing → testing → test-reviewing → test-done → done
```

## 各阶段详情

### 代码审核（code-reviewing）

| 谁做 | 动作 | 状态 | 通知 |
|------|------|------|------|
| **Dev Agent** | 开发完成，commit + push | `dev-done` | — |
| **Dev Agent** | → 设置状态 | `code-reviewing` | **@代码审核助手** |
| **代码审核助手** | 审核代码 | `code-reviewing` | — |

### 交叉审核（cr-reviewing）

| 审核结果 | 动作 | 状态 | 通知 |
|---------|------|------|------|
| ✅ 通过 | 代码审核通过 | `cr-reviewing` | **@吴斌** 交叉审核 |
| ❌ 驳回 | 打回修复 | `dev-fixing` | **@Dev Agent**（附驳回原因） |

吴斌确认后 → **@测试 Agent** 进入测试

### 测试验证（testing）

| 测试结果 | 动作 | 状态 | 通知 |
|---------|------|------|------|
| ✅ 通过 | 测试完成 | `test-reviewing` | **@项目负责人** 确认 |
| ❌ 失败 | 打回修复 | `dev-fixing` | **@Dev Agent**（附测试报告） |

项目负责人确认后 → `test-done` → `done`

测试失败打回流程：`dev-fixing` → Dev 修复 → `dev-done` → 重新代码审核+测试

## 修复循环

```
dev-done → code-reviewing → cr-reviewing（驳回）→ dev-fixing → dev-done
dev-done → testing（失败）→ dev-fixing → dev-done
```

## Dev Agent 在 dev-done 后的动作

1. 更新任务状态为 `dev-done`
2. 使用 lark-cli 或 send_message **@ 代码审核助手**（ou_5bef2b7e0871bd75e47971357ad6b666）
3. 消息内容：任务ID + 项目名 + 分支名 + "请进行代码审核"
4. **必须使用当前群的 chat_id，不能硬编码**

## ⚠️ 状态更新 Pitfalls

### 任务文件在 hermes 分支，不是 master
```bash
cd /Users/apple/work/tc-flight-int-reversepromotion
git checkout hermes  # 必须先切换到 hermes 分支
```

### git push 被拒绝时用 merge，不用 rebase
```bash
# ❌ rebase 在 dumb terminal 中会失败
git pull origin hermes --rebase  # Terminal is dumb, but EDITOR unset

# ✅ 用 merge
git pull origin hermes --no-rebase
# 解决冲突后：git add + git commit + git push
```
