---
name: debugging
description: "Debugging methodology and tool-specific guides for Python and Node.js."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [debugging, python, nodejs, pdb, debugpy, node-inspect, cdp, root-cause, troubleshooting]
    related_skills: [test-driven-development, systematic-debugging]
---

# Debugging

Three-layer approach: methodology first, then tool-specific recipes.

---

## §1 — Debugging Methodology

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

### The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

### Phase 1: Understand the Problem

Before writing ANY fix code:

1. **Read the error** — full traceback, error message, exit code
2. **Reproduce it** — can you make it happen reliably? If not, gather more data
3. **Identify the boundary** — where does expected behavior stop and actual behavior start?
4. **Check recent changes** — `git log --oneline -10`, `git diff HEAD~3`

### Phase 2: Investigate Root Cause

1. **Read the code** — actually read the failing function and its callers
2. **Check the data** — what are the actual values at the failure point?
3. **Trace the flow** — follow the execution path from input to failure
4. **Check assumptions** — what did the developer assume that isn't true?

### Phase 3: Verify Root Cause

Before fixing, confirm:

- Can you explain WHY the bug happens with this root cause?
- Does changing the root cause change the behavior?
- Can you reproduce the bug by introducing the root cause in isolation?

### Phase 4: Fix and Verify

1. Fix the root cause, not the symptom
2. Add a test that catches this specific failure
3. Verify the fix doesn't break anything else
4. Run the full test suite

### Anti-patterns

- "Let me try changing X and see if it works" — random fixes
- "I'll add a try/except to suppress the error" — symptom masking
- "It works on my machine" — environment assumption
- "Let me rewrite the whole thing" — nuclear option before investigation

---

## §2 — Python Debugging (pdb + debugpy)

Three tools, picked by situation:

| Tool | When |
|---|---|
| `breakpoint()` + pdb | Local, interactive, simplest |
| `python -m pdb` | Launch script under pdb, no source edits |
| `debugpy` | Remote / headless / attach to running process |

### pdb Quick Reference

| Command | Action |
|---|---|
| `n` | next (step over) |
| `s` | step into |
| `r` | return from function |
| `c` | continue |
| `l` / `ll` | list source / full function |
| `w` | where (stack trace) |
| `u` / `d` | up / down stack |
| `p expr` / `pp expr` | print / pretty-print |
| `b file:line` | set breakpoint |
| `b func` | break on function entry |
| `cl N` | clear breakpoint N |
| `!stmt` | execute arbitrary Python |
| `interact` | full Python REPL in current scope |
| `q` | quit |

### Recipe 1: Local breakpoint (easiest)

```python
def compute(x, y):
    result = some_helper(x)
    breakpoint()           # drops into pdb here
    return result + y
```

Run normally. Land at `breakpoint()` with full access to locals.

**Remove before committing:** `rg -n 'breakpoint()' --type py`

### Recipe 2: Launch under pdb

```bash
python -m pdb path/to/script.py arg1 arg2
(Pdb) b path/to/script.py:42
(Pdb) c
```

### Recipe 3: Debug pytest tests

```bash
python -m pytest tests/foo_test.py::test_bar --pdb -p no:xdist
```

**Critical:** pdb does NOT work under pytest-xdist. Always use `-p no:xdist` or `-n 0`.

### Recipe 4: Post-mortem on exception

```python
import pdb, sys
try:
    run_the_thing()
except Exception:
    pdb.post_mortem(sys.exc_info()[2])
```

Or wrap a script:
```bash
python -m pdb -c continue script.py
```

### Recipe 5: Remote debug with debugpy

**Source-edit pattern:**
```python
import debugpy
debugpy.listen(("127.0.0.1", 5678))
print("debugpy listening on 5678...")
debugpy.wait_for_client()
```

**No source edit:**
```bash
python -m debugpy --listen 127.0.0.1:5678 --wait-for-client your_script.py
```

**Attach to running process:**
```bash
python -m debugpy --listen 127.0.0.1:5678 --pid <pid>
```

**Simpler alternative — remote-pdb:**
```python
from remote_pdb import set_trace
set_trace(host="127.0.0.1", port=4444)
# Then: nc 127.0.0.1 4444 → get (Pdb) prompt
```

### Common Pitfalls

1. **pdb under pytest-xdist silently does nothing** — always use `-p no:xdist`
2. **`breakpoint()` in CI hangs** — never commit it
3. **`PYTHONBREAKPOINT=0`** disables all breakpoints — check env
4. **debugpy.attach fails on hardened kernels** — `echo 0 > /proc/sys/kernel/yama/ptrace_scope`
5. **pdb doesn't follow forks** — each child needs its own breakpoint

---

## §3 — Node.js Debugging (node inspect + CDP)

Two tools:

| Tool | When |
|---|---|
| `node inspect` | Built-in, zero install, CLI REPL |
| CDP via `chrome-remote-interface` | Scriptable automation |

### `node inspect` Quick Reference

```bash
node inspect script.js                    # paused on first line
node --inspect-brk $(which tsx) script.ts # TypeScript
```

| Command | Action |
|---|---|
| `c` / `cont` | continue |
| `n` / `next` | step over |
| `s` / `step` | step into |
| `o` / `out` | step out |
| `pause` | pause running code |
| `sb('file.js', 42)` | set breakpoint |
| `sb('functionName')` | break on function call |
| `cb('file.js', 42)` | clear breakpoint |
| `bt` | backtrace |
| `list(5)` | show source around position |
| `repl` | REPL in current scope |
| `exec expr` | evaluate expression |
| `restart` | restart script |
| `.exit` | quit |

### Attaching to Running Process

```bash
kill -SIGUSR1 <pid>                    # enable inspector
# Node prints: Debugger listening on ws://127.0.0.1:9229/<uuid>
node inspect -p <pid>                  # attach CLI
```

### Starting with Inspector

```bash
node --inspect script.js           # listen, keep running
node --inspect-brk script.js       # listen AND pause on first line
node --inspect=0.0.0.0:9230 script.js  # custom host:port
```

### Programmatic CDP

```bash
npm i -g chrome-remote-interface
```

```javascript
const CDP = require('chrome-remote-interface');
(async () => {
  const client = await CDP({ port: 9229 });
  const { Debugger, Runtime } = client;
  Debugger.paused(async ({ callFrames }) => {
    const top = callFrames[0];
    console.log(`PAUSED @ ${top.url}:${top.location.lineNumber + 1}`);
    // Walk scopes for locals
    for (const scope of top.scopeChain) {
      if (scope.type === 'local' || scope.type === 'closure') {
        const { result } = await Runtime.getProperties({
          objectId: scope.object.objectId, ownProperties: true,
        });
        for (const p of result) {
          console.log(`  ${scope.type}.${p.name} =`, p.value?.value);
        }
      }
    }
    await Debugger.resume();
  });
  await Debugger.enable();
  await Runtime.enable();
  await Debugger.setBreakpointByUrl({ urlRegex: '.*app\\.tsx$', lineNumber: 119 });
  await Runtime.runIfWaitingForDebugger();
})();
```

### Common Pitfalls

1. **Wrong line numbers in TS** — breakpoints hit emitted JS. Use `node --enable-source-maps` for sourcemaps.
2. **`--inspect` vs `--inspect-brk`** — `--inspect` doesn't pause; attach too late = missed breakpoint
3. **Port collisions** — default 9229. Use `--inspect=0` for random port, check `/json/list`
4. **Child processes** — `--inspect` on parent doesn't inspect children. Use `NODE_OPTIONS='--inspect-brk'`
5. **Security** — `--inspect=0.0.0.0:9229` exposes arbitrary code execution. Always bind to 127.0.0.1

---

## Verification Checklist

After a debug session:

- [ ] Breakpoint actually hits (check `PYTHONBREAKPOINT`, xdist, port binding)
- [ ] `where` / `bt` shows the expected call stack
- [ ] No stray `breakpoint()` / `set_trace()` / `debugpy.listen` in committed code:
  ```bash
  rg -n 'breakpoint\(\)|set_trace\(|debugpy\.listen' --type py
  ```
