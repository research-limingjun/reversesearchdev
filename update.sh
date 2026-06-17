#!/usr/bin/env bash
# Pull latest reversesearchdev distribution (hermes profile update).
# On divergence: try auto-merge + publish; on merge conflict, agent-conflict-branch.sh.
#
# Usage: ./update.sh
set -euo pipefail

PROFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROFILE_DIR"

PROFILE_NAME="${PROFILE_NAME:-reversesearchdev}"
STATE_FILE="$PROFILE_DIR/local/dist_sync_state.json"
MANIFEST="$PROFILE_DIR/distribution.yaml"
PUBLISH_CONFIG="$PROFILE_DIR/publish.config"
BRANCH="${BRANCH:-main}"
GIT_REMOTE=""
CONFLICT_STRATEGY="${CONFLICT_STRATEGY:-distribution_branch}"

mkdir -p "$PROFILE_DIR/local"

_load_publish_config() {
  if [[ -f "$PUBLISH_CONFIG" ]]; then
    # shellcheck source=/dev/null
    source "$PUBLISH_CONFIG"
  fi
  PROFILE_NAME="${PROFILE_NAME:-reversesearchdev}"
  BRANCH="${BRANCH:-main}"
  GIT_REMOTE="${REMOTE:-}"
  CONFLICT_STRATEGY="${CONFLICT_STRATEGY:-distribution_branch}"
}

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

_git_fetch_quiet() {
  git fetch origin "$BRANCH" --quiet 2>/dev/null || git fetch origin --quiet 2>/dev/null
}

_local_ahead_count() {
  if [[ ! -d .git ]]; then
    echo 0
    return
  fi
  git rev-list --count "origin/$BRANCH..HEAD" 2>/dev/null || echo 0
}

_remote_ahead_count() {
  if [[ ! -d .git ]]; then
    echo 0
    return
  fi
  git rev-list --count "HEAD..origin/$BRANCH" 2>/dev/null || echo 0
}

_remote_branch_sha() {
  git rev-parse "origin/$BRANCH" 2>/dev/null || true
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

_write_state() {
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
data["last_action"] = "pull"
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

_resolve_remote_url() {
  python3 - "$MANIFEST" "$PUBLISH_CONFIG" <<'PY'
import re, sys
from pathlib import Path

manifest = Path(sys.argv[1])
publish_cfg = Path(sys.argv[2])
url = ""
if manifest.is_file():
    text = manifest.read_text(encoding="utf-8")
    m = re.search(r"^source:\s*['\"]?(.+?)['\"]?\s*$", text, re.M)
    if m:
        url = m.group(1).strip()
if not url and publish_cfg.is_file():
    for line in publish_cfg.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("REMOTE="):
            url = line.split("=", 1)[1].strip().strip('"').strip("'")
            break
if not url:
    sys.exit(1)
print(url)
PY
}

_load_publish_config

if [[ ! -f "$MANIFEST" ]]; then
  echo "Error: distribution.yaml not found" >&2
  exit 1
fi

REMOTE_URL="$(_resolve_remote_url 2>/dev/null || true)"
GIT_REMOTE="${GIT_REMOTE:-$REMOTE_URL}"

if [[ -d .git && -n "$GIT_REMOTE" ]]; then
  _ensure_origin_remote "$GIT_REMOTE" || true
  _git_fetch_quiet || true
fi

LOCAL_DIRTY="$(_list_owned_dirty | _join_lines || true)"
LOCAL_AHEAD="$(_local_ahead_count)"
REMOTE_AHEAD="$(_remote_ahead_count)"

LOCAL_NEEDS_PUBLISH=false
if [[ -n "$LOCAL_DIRTY" ]] || [[ "${LOCAL_AHEAD:-0}" -gt 0 ]]; then
  LOCAL_NEEDS_PUBLISH=true
fi

# Divergence: try clean merge + publish first; real merge conflicts → conflict branch
if [[ "$LOCAL_NEEDS_PUBLISH" == true ]] && [[ "${REMOTE_AHEAD:-0}" -gt 0 ]]; then
  LOCAL_HEAD="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
  REMOTE_HEAD="$(git rev-parse --short "origin/$BRANCH" 2>/dev/null || echo unknown)"
  LOCAL_DESC="$LOCAL_DIRTY"
  if [[ -z "$LOCAL_DESC" ]]; then
    LOCAL_DESC="已 commit 未 push（领先 ${LOCAL_AHEAD} 个提交）"
  fi
  if [[ "${CONFLICT_STRATEGY}" == "distribution_branch" ]]; then
    export CONFLICT_LOCAL_DESC="$LOCAL_DESC"
    export CONFLICT_LOCAL_HEAD="$LOCAL_HEAD"
    export CONFLICT_REMOTE_HEAD="$REMOTE_HEAD"
    export CONFLICT_REMOTE_AHEAD="$REMOTE_AHEAD"
    chmod +x "$PROFILE_DIR/scripts/agent-divergence-merge.sh"
    chmod +x "$PROFILE_DIR/scripts/agent-conflict-branch.sh"
    set +e
    MERGE_OUTPUT="$("$PROFILE_DIR/scripts/agent-divergence-merge.sh" 2>&1)"
    MERGE_EXIT=$?
    set -e
    if [[ "$MERGE_EXIT" -eq 0 ]]; then
      printf '%s\n' "$MERGE_OUTPUT"
      exit 0
    fi
    if [[ "$MERGE_EXIT" -eq 2 ]]; then
      exec "$PROFILE_DIR/scripts/agent-conflict-branch.sh"
    fi
    printf '%s\n' "$MERGE_OUTPUT" >&2
    exit 1
  fi
  echo "[${PROFILE_NAME}] 配置同步分叉，需人工介入" >&2
  echo "本机未发布: ${LOCAL_DESC}" >&2
  echo "远端领先 ${REMOTE_AHEAD} 个提交 (${LOCAL_HEAD}..${REMOTE_HEAD})" >&2
  exit 1
fi

# Local changes only — update does not publish
if [[ "$LOCAL_NEEDS_PUBLISH" == true ]]; then
  echo "Error: 本机有未发布改动，请先执行 ./publish.sh" >&2
  [[ -n "$LOCAL_DIRTY" ]] && echo "  改动: ${LOCAL_DIRTY}" >&2
  exit 1
fi

# Nothing to pull
if [[ "${REMOTE_AHEAD:-0}" -eq 0 ]]; then
  VERSION="$(_read_version)"
  echo "Already up to date: ${PROFILE_NAME}@v${VERSION}"
  exit 0
fi

# Pull latest
if ! hermes -p "$PROFILE_NAME" profile update "$PROFILE_NAME" -y; then
  echo "[${PROFILE_NAME}] profile update 失败，请检查 source 与 Git 权限" >&2
  exit 1
fi

if [[ -d .git ]]; then
  _git_fetch_quiet || true
fi

REMOTE_SHA="$(_remote_branch_sha)"
NEW_VERSION="$(_read_version)"
if [[ -n "$REMOTE_SHA" ]]; then
  _write_state "$REMOTE_SHA" "$NEW_VERSION"
fi

echo "Updated ${PROFILE_NAME}@v${NEW_VERSION}"
echo "  SOUL.md / skills / scripts（memories 与 .env 未改动）"
