#!/usr/bin/env bash
# Try merging origin/$BRANCH when local is unpublished and remote is ahead.
# On clean merge: publish merged result. On merge conflict: exit 2 for agent-conflict-branch.sh.
set -euo pipefail

SKILL_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$(cd "$SKILL_SCRIPTS/../../.." && pwd)"
cd "$PROFILE_DIR"

# shellcheck source=_lib.sh
source "$SKILL_SCRIPTS/_lib.sh"

STATE_FILE="$PROFILE_DIR/local/dist_sync_state.json"
MANIFEST="$PROFILE_DIR/distribution.yaml"
GIT_REMOTE=""

CONFLICT_LOCAL_DESC="${CONFLICT_LOCAL_DESC:-}"
CONFLICT_REMOTE_AHEAD="${CONFLICT_REMOTE_AHEAD:-0}"

mkdir -p "$PROFILE_DIR/local"
_hd_load_distribution_config "$MANIFEST"
GIT_REMOTE="${REMOTE:-}"

_join_lines() {
  local first=1 line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ $first -eq 1 ]]; then
      printf '%s' "$line"
      first=0
    else
      printf ', %s' "$line"
    fi
  done
}

_list_owned_dirty() {
  [[ -d .git ]] || return 0
  python3 - "$MANIFEST" <<'PY'
import re, subprocess, sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")
owned = []
in_owned = False
for line in text.splitlines():
    if line.strip().startswith("distribution_owned:"):
        in_owned = True
        continue
    if not in_owned:
        continue
    m = re.match(r"^-\s+(.+)", line) or re.match(r"^\s+-\s+(.+)", line)
    if m:
        owned.append(m.group(1).strip().strip("'\""))
        continue
    if line.strip():
        break

for p in owned:
    out = subprocess.run(
        ["git", "status", "--porcelain", "--", p],
        capture_output=True, text=True,
    )
    if out.stdout.strip():
        print(p)
PY
}

_ensure_origin_remote() {
  local remote="$1"
  [[ -n "$remote" ]] || return 1
  if git remote get-url origin &>/dev/null; then
    local current
    current="$(git remote get-url origin)"
    if [[ "$current" != "$remote" ]]; then
      git remote set-url origin "$remote"
    fi
  else
    git remote add origin "$remote"
  fi
}

_read_version() {
  python3 - "$MANIFEST" <<'PY'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8")
m = re.search(r"^version:\s*['\"]?([^'\"\n]+)", text, re.M)
print(m.group(1).strip() if m else "?")
PY
}

_remote_branch_sha() {
  git rev-parse "origin/$BRANCH" 2>/dev/null || true
}

_clear_conflict_state() {
  python3 - "$STATE_FILE" <<'PY'
import json, sys
from pathlib import Path

p = Path(sys.argv[1])
if not p.is_file():
    raise SystemExit(0)
try:
    data = json.loads(p.read_text(encoding="utf-8"))
except Exception:
    raise SystemExit(0)
for key in (
    "pending_conflict_branch",
    "pending_conflict_local_sha",
    "pending_conflict_remote_sha",
    "pending_conflict_at",
):
    data.pop(key, None)
p.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
}

_write_merge_publish_state() {
  local sha="$1" version="$2"
  python3 - "$STATE_FILE" "$sha" "$version" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path

p = Path(sys.argv[1])
data = {}
if p.is_file():
    try:
        data = json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        data = {}
data["last_remote_sha"] = sys.argv[2]
data["last_version"] = sys.argv[3]
data["last_sync_at"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
data["last_action"] = "merge_publish"
for key in (
    "pending_conflict_branch",
    "pending_conflict_local_sha",
    "pending_conflict_remote_sha",
    "pending_conflict_at",
):
    data.pop(key, None)
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
}

_has_merge_conflicts() {
  git diff --name-only --diff-filter=U 2>/dev/null | grep -q .
}

_abort_merge_if_needed() {
  if [[ -f .git/MERGE_HEAD ]] || _has_merge_conflicts; then
    git merge --abort 2>/dev/null || true
  fi
}

if [[ ! -d .git ]]; then
  echo "[${PROFILE_NAME}] 分叉合并失败: 非 git 仓库" >&2
  exit 1
fi

_ensure_origin_remote "$GIT_REMOTE" || true
git fetch origin "$BRANCH" --quiet 2>/dev/null || git fetch origin --quiet 2>/dev/null || true

LOCAL_DESC="$CONFLICT_LOCAL_DESC"
if [[ -z "$LOCAL_DESC" ]]; then
  LOCAL_DESC="$(_list_owned_dirty | _join_lines || true)"
fi
if [[ -z "$LOCAL_DESC" ]]; then
  LOCAL_DESC="已 commit 未 push"
fi

DIRTY_PATHS=()
while IFS= read -r p; do
  [[ -n "$p" ]] && DIRTY_PATHS+=("$p")
done < <(_list_owned_dirty)

if [[ ${#DIRTY_PATHS[@]} -gt 0 ]]; then
  git add "${DIRTY_PATHS[@]}"
  if ! git diff --cached --quiet; then
    git commit -m "WIP: distribution sync divergence ($(hostname -s 2>/dev/null || hostname))"
  fi
  LOCAL_DESC="$(_list_owned_dirty | _join_lines || true)"
  if [[ -z "$LOCAL_DESC" ]]; then
    LOCAL_DESC="$(git diff-tree --no-commit-id --name-only -r HEAD | _join_lines || echo "（见最近提交）")"
  fi
fi

if ! git merge "origin/$BRANCH" --no-edit; then
  _abort_merge_if_needed
  exit 2
fi

if _has_merge_conflicts; then
  _abort_merge_if_needed
  exit 2
fi

PUBLISH_OUTPUT=""
if ! PUBLISH_OUTPUT="$("$SKILL_SCRIPTS/publish.sh" 2>&1)"; then
  cat <<EOF
[${PROFILE_NAME}] 分叉已合并但自动发布失败
本机改动: ${LOCAL_DESC}
${PUBLISH_OUTPUT}
EOF
  exit 1
fi

if echo "$PUBLISH_OUTPUT" | grep -q "^No changes to publish\."; then
  git fetch origin "$BRANCH" --quiet 2>/dev/null || true
  REMOTE_SHA="$(_remote_branch_sha)"
  VERSION="$(_read_version)"
  if [[ -n "$REMOTE_SHA" ]]; then
    _write_merge_publish_state "$REMOTE_SHA" "$VERSION"
  fi
  _clear_conflict_state
  cat <<EOF
[${PROFILE_NAME}] 分叉已自动合并: ${PROFILE_NAME}@v${VERSION}
本机改动: ${LOCAL_DESC}
已合并远端 ${CONFLICT_REMOTE_AHEAD} 个提交
EOF
  exit 0
fi

if ! echo "$PUBLISH_OUTPUT" | grep -q "Published ${PROFILE_NAME}@"; then
  cat <<EOF
[${PROFILE_NAME}] 分叉已合并但自动发布失败
本机改动: ${LOCAL_DESC}
${PUBLISH_OUTPUT}
EOF
  exit 1
fi

git fetch origin "$BRANCH" --quiet 2>/dev/null || true
REMOTE_SHA="$(_remote_branch_sha)"
NEW_VERSION="$(_read_version)"
if [[ -n "$REMOTE_SHA" ]]; then
  _write_merge_publish_state "$REMOTE_SHA" "$NEW_VERSION"
fi
_clear_conflict_state

cat <<EOF
[${PROFILE_NAME}] 分叉已自动合并并发布至 v${NEW_VERSION}
本机改动: ${LOCAL_DESC}
已合并远端 ${CONFLICT_REMOTE_AHEAD} 个提交
远端: ${GIT_REMOTE}
EOF
