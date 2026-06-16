#!/usr/bin/env bash
# Bidirectional distribution sync: auto-publish local changes, pull remote updates, Feishu via cron stdout.
# Register: ./scripts/setup-agent-sync-cron.sh
set -euo pipefail

PROFILE_NAME="${PROFILE_NAME:-reversesearchdev}"
PROFILE_DIR="${HERMES_HOME:-$HOME/.hermes/profiles/$PROFILE_NAME}"
STATE_FILE="$PROFILE_DIR/local/dist_sync_state.json"
MANIFEST="$PROFILE_DIR/distribution.yaml"
PUBLISH_CONFIG="$PROFILE_DIR/publish.config"
BRANCH="${BRANCH:-main}"
GIT_REMOTE=""
CONFLICT_STRATEGY="${CONFLICT_STRATEGY:-distribution_branch}"

cd "$PROFILE_DIR"
mkdir -p "$PROFILE_DIR/local"

_load_publish_config() {
  if [[ -f "$PUBLISH_CONFIG" ]]; then
    # shellcheck source=/dev/null
    source "$PUBLISH_CONFIG"
  fi
  BRANCH="${BRANCH:-main}"
  GIT_REMOTE="${REMOTE:-}"
  CONFLICT_STRATEGY="${CONFLICT_STRATEGY:-distribution_branch}"
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

_resolve_remote_url() {
  python3 - "$MANIFEST" "$PUBLISH_CONFIG" <<'PY'
import re
import sys
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

_read_state_sha() {
  python3 - "$STATE_FILE" <<'PY'
import json, sys
from pathlib import Path
p = Path(sys.argv[1])
if not p.is_file():
    print("")
else:
    try:
        print(json.loads(p.read_text()).get("last_remote_sha", "") or "")
    except Exception:
        print("")
PY
}

_write_state() {
  local sha="$1" version="$2" action="${3:-}"
  python3 - "$STATE_FILE" "$sha" "$version" "$action" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path

p = Path(sys.argv[1])
data = {
    "last_remote_sha": sys.argv[2],
    "last_version": sys.argv[3],
    "last_sync_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
}
if sys.argv[4]:
    data["last_action"] = sys.argv[4]
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
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

dirty = []
for p in owned:
    out = subprocess.run(
        ["git", "status", "--porcelain", "--", p],
        capture_output=True, text=True,
    )
    if out.stdout.strip():
        dirty.append(p)

for p in dirty:
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
  if [[ -d .git ]]; then
    git rev-parse "origin/$BRANCH" 2>/dev/null && return 0
  fi
  local ls_url remote_sha
  ls_url="$(_normalize_ls_remote_url "$1")"
  remote_sha="$(git ls-remote "$ls_url" "refs/heads/$BRANCH" 2>/dev/null | awk '{print $1}' | head -1)"
  [[ -n "$remote_sha" ]] && echo "$remote_sha"
}

_normalize_ls_remote_url() {
  local url="$1"
  case "$url" in
    https://github.com/*)
      echo "${url%.git}"
      ;;
    git@github.com:*)
      echo "https://github.com/${url#git@github.com:}" | sed 's/.git$//'
      ;;
    *)
      echo "${url%.git}"
      ;;
  esac
}

_load_publish_config

REMOTE_URL="$(_resolve_remote_url)" || {
  echo "[${PROFILE_NAME}] distribution 同步失败: 未找到 source/REMOTE" >&2
  exit 1
}

GIT_REMOTE="${GIT_REMOTE:-$REMOTE_URL}"

if [[ -d .git ]]; then
  _ensure_origin_remote "$GIT_REMOTE" || true
  _git_fetch_quiet || true
fi

LOCAL_DIRTY="$(_list_owned_dirty | _join_lines || true)"
LOCAL_AHEAD="$(_local_ahead_count)"
REMOTE_AHEAD="$(_remote_ahead_count)"
REMOTE_SHA="$(_remote_branch_sha "$REMOTE_URL" || true)"

if [[ -z "$REMOTE_SHA" ]]; then
  echo "[${PROFILE_NAME}] distribution 同步失败: 无法访问远端 $REMOTE_URL" >&2
  exit 1
fi

LOCAL_NEEDS_PUBLISH=false
if [[ -n "$LOCAL_DIRTY" ]] || [[ "${LOCAL_AHEAD:-0}" -gt 0 ]]; then
  LOCAL_NEEDS_PUBLISH=true
fi

# Conflict + pull: delegate to update.sh
if [[ "$LOCAL_NEEDS_PUBLISH" == true ]] && [[ "${REMOTE_AHEAD:-0}" -gt 0 ]]; then
  chmod +x "$PROFILE_DIR/update.sh"
  "$PROFILE_DIR/update.sh"
  exit $?
fi

# Publish: local changes only, remote not ahead
if [[ "$LOCAL_NEEDS_PUBLISH" == true ]]; then
  PUBLISH_OUTPUT=""
  if ! PUBLISH_OUTPUT="$("$PROFILE_DIR/publish.sh" 2>&1)"; then
    cat <<EOF
[${PROFILE_NAME}] 自动发布失败
${PUBLISH_OUTPUT}
EOF
    exit 1
  fi

  if echo "$PUBLISH_OUTPUT" | grep -q "^No changes to publish\."; then
    exit 0
  fi

  if ! echo "$PUBLISH_OUTPUT" | grep -q "Published reversesearchdev@"; then
    cat <<EOF
[${PROFILE_NAME}] 自动发布失败
${PUBLISH_OUTPUT}
EOF
    exit 1
  fi

  _git_fetch_quiet || true
  REMOTE_SHA="$(_remote_branch_sha "$REMOTE_URL")"
  NEW_VERSION="$(_read_version)"
  _write_state "$REMOTE_SHA" "$NEW_VERSION" "publish"
  _clear_conflict_state

  if [[ -n "$LOCAL_DIRTY" ]]; then
    PUBLISH_FILES="$LOCAL_DIRTY"
  else
    PUBLISH_FILES="$(git log --oneline -"${LOCAL_AHEAD:-1}" --name-only --pretty=format: "origin/$BRANCH" 2>/dev/null | sed '/^$/d' | sort -u | _join_lines || echo "（见最近提交）")"
  fi

  cat <<EOF
[${PROFILE_NAME}] 数字人配置已自动发布至 v${NEW_VERSION}
变更: ${PUBLISH_FILES}
远端: ${REMOTE_URL}
EOF
  exit 0
fi

# Pull: remote ahead, local clean
if [[ "${REMOTE_AHEAD:-0}" -gt 0 ]]; then
  chmod +x "$PROFILE_DIR/update.sh"
  "$PROFILE_DIR/update.sh"
  exit $?
fi

# Silent: nothing to do
exit 0
