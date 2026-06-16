---
name: kanban
description: "Hermes Kanban: orchestrator playbook and worker pitfalls/examples."
version: 3.0.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [kanban, multi-agent, orchestration, routing, workflow, collaboration]
---

# Hermes Kanban

Two roles in the Kanban system: orchestrator (routes work) and worker (executes work).

The core lifecycle is auto-injected via `KANBAN_GUIDANCE` in every worker's system prompt. This skill provides the deeper playbook for both roles.

---

## §1 — Orchestrator Playbook

> **Core rule:** Decompose, don't execute. Your job is routing, not implementation.

### Anti-Temptation Rules

1. **Don't do the work yourself.** When you see a task, your job is to create child tasks and assign them to the right specialist profiles.
2. **Don't refine the spec beyond routing.** If a task needs more detail, create a triage task for a specifier profile.
3. **Don't review code.** Create a reviewer task.
4. **Don't debug.** Create a debugging task.

### Fan-Out Pattern

```
kanban_create(title="Implement auth module", assignee="developer-a", parents=[parent_id])
kanban_create(title="Write tests for auth", assignee="developer-b", parents=[parent_id])
kanban_create(title="Review auth PR", assignee="reviewer", parents=[child1_id, child2_id])
```

### Decomposition Guidelines

- Each child task should be completable by ONE profile in ONE session
- Tasks should be independent when possible (parallel execution)
- Use `parents=[]` to express dependencies — child won't promote to `ready` until all parents are `done`
- Set `priority` for tiebreaker when multiple tasks compete for same assignee

### Completing Your Task

```
kanban_complete(summary="Decomposed into 3 tasks: auth implementation, tests, review", created_cards=["task1", "task2", "task3"])
```

---

## §2 — Worker Pitfalls & Examples

> You're a worker spawned by the dispatcher. Your lifecycle: orient → work → heartbeat → block/complete.

### Orient First

```
kanban_show()  # Always first call — shows task, parent handoffs, prior attempts, comments
```

### Good Handoff Shapes

**Summary:** 1-3 human-readable sentences naming concrete artifacts.
```
kanban_complete(summary="Added JWT auth module with login/register endpoints. 15 tests pass.", metadata={"changed_files": ["src/auth.py", "tests/test_auth.py"], "tests_run": 15})
```

**Bad:** "Done" or "Completed the task"

### Heartbeat on Long Operations

```
kanban_heartbeat(note="Training epoch 5/20, loss=0.34")  # Every few minutes during long work
```

If your task may run >1 hour, you MUST heartbeat at least once per hour. The dispatcher reclaims tasks with no heartbeat in the last hour.

### When to Block

```
kanban_block(reason="Need human decision: which database should we use — PostgreSQL or SQLite?")
```

Block on: missing credentials, UX choices, paywalled sources, peer output you need first.
Don't block on: things you can resolve yourself.

### Retry Awareness

If this is a retry (prior attempts exist in `kanban_show`), read the prior attempt's comments and learn from what failed.

### Creating Follow-Up Tasks

If you discover follow-up work, create it — don't do it yourself:
```
kanban_create(title="Add rate limiting to auth endpoints", assignee="developer-a", parents=[current_task_id])
```

### Common Mistakes

1. **Completing without actually finishing** — block instead
2. **Not reading parent handoff** — always call `kanban_show()` first
3. **Putting secrets in summary/metadata** — these are durable forever
4. **Not heartbeating on long tasks** — gets reclaimed after 1 hour of silence
5. **Auto-completing work that needs review** — use `kanban_comment` + `kanban_block(reason="review-required")`
