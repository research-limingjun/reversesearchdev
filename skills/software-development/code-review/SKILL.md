---
name: code-review
description: "Code review methodology: pre-commit verification and receiving feedback."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [code-review, security, verification, quality, pre-commit, feedback]
    related_skills: [test-driven-development, github]
---

# Code Review

Two perspectives on code review: verifying your own work before committing, and responding to feedback from others.

For GitHub-specific PR review tools (inline comments, formal reviews), see the `github` skill §2.

---

## §1 — Pre-Commit Verification (Requesting Review)

Automated verification pipeline before code lands. Static scans, quality gates, independent reviewer subagent, and auto-fix loop.

**Core principle:** No agent should verify its own work. Fresh context finds what you miss.

### When to Use

- After implementing a feature or bug fix, before `git commit` or `git push`
- When user says "commit", "push", "ship", "done", "verify", "review before merge"
- After completing a task with 2+ file edits in a git repo

**Skip for:** documentation-only changes, pure config tweaks, or when user says "skip verification".

### Step 1: Get the Diff

```bash
git diff --cached
```

If empty: `git diff` then `git diff HEAD~1 HEAD`.

### Step 2: Static Security Scan

```bash
# Secrets in code
git diff --cached | grep -in "password\|secret\|api_key\|token.*=\|private_key\|AWS_"

# Debug statements left behind
git diff --cached | grep -n "print(\|console\.log\|TODO\|FIXME\|debugger\|breakpoint()"

# Large files accidentally staged
git diff --cached --stat | sort -t'|' -k2 -rn | head -10

# Merge conflict markers
git diff --cached | grep -n "<<<<<<\|>>>>>>\|======="
```

### Step 3: Quality Gates

Run the project's linter and test suite:

```bash
# Lint
ruff check . 2>&1 | head -30
# or: eslint, clippy, etc.

# Tests
python -m pytest 2>&1 | tail -20
# or: npm test, cargo test, go test ./...
```

### Step 4: Independent Review (Subagent)

For significant changes (5+ files, new features, security-sensitive code), spawn a review subagent:

```
delegate_task(goal="Review this diff for bugs, security issues, and code quality. Be thorough and critical.", context="<paste the diff>")
```

The subagent has fresh context and catches what the implementer misses.

### Step 5: Auto-Fix Loop

1. Run static scan → fix findings
2. Run linter → auto-fix where possible (`ruff check --fix .`)
3. Run tests → fix failures
4. Re-run all checks until clean
5. Max 3 iterations, then report remaining issues

### Step 6: Final Verification

```bash
# Confirm no stray debug artifacts
rg -n 'breakpoint\(\)|set_trace\(|console\.log|debugger' --type py --type js --type ts

# Confirm tests pass
python -m pytest -x 2>&1 | tail -5

# Confirm no secrets
git diff --cached | grep -in "password\|secret\|api_key\|token.*=" || echo "Clean"
```

---

## §2 — Responding to Review Feedback (Receiving Review)

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

### The Response Pattern

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

### Forbidden Responses

**NEVER:**
- "You're absolutely right!" (performative agreement)
- "Great point!" / "Excellent feedback!" (empty flattery)
- "Let me implement that now" (before verification)

**INSTEAD:**
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if wrong
- Just start working (actions > words)

### Handling Unclear Feedback

When feedback is ambiguous:

1. Restate your understanding: "Are you saying X should be Y because Z?"
2. Ask for specifics: "Can you point to the line or show an example?"
3. If still unclear after clarification: implement the most conservative interpretation

### When Feedback is Wrong

Push back with technical reasoning:

- "I considered that approach but chose X because Y. The issue is Z with the suggested approach."
- "That would break [specific thing] because [reason]. Here's an alternative that addresses your concern."
- Cite code, docs, or test results — not opinions

### When Feedback is Right

- Acknowledge the technical point (not the person)
- Implement the fix
- Add a test if the feedback caught a real bug
- Don't over-thank — just do the work

### Implementing Feedback

1. One item at a time
2. Test after each change
3. Run the full test suite before pushing
4. Commit with clear message about what changed and why

### Decision Matrix

| Feedback Type | Action |
|---------------|--------|
| Correct + clear | Implement immediately |
| Correct + unclear | Ask for clarification, then implement |
| Incorrect + clear | Push back with technical reasoning |
| Incorrect + unclear | Ask for clarification, then evaluate |
| Style preference | Follow project conventions if they exist, otherwise use judgment |
| Nitpick | Fix if trivial, skip if it would change behavior |
