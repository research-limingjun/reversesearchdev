#!/usr/bin/env bash
# Core watchdog logic (called from profile/scripts/agent-sync-watchdog.sh).
set -euo pipefail

SKILL_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$(cd "$SKILL_SCRIPTS/../../.." && pwd)"
cd "$PROFILE_DIR"

# shellcheck source=_lib.sh
source "$SKILL_SCRIPTS/_lib.sh"

STATE_FILE="$PROFILE_DIR/local/dist_sync_state.json"
MANIFEST="$PROFILE_DIR/distribution.yaml"
ENV_FILE="$PROFILE_DIR/.env"
GIT_REMOTE=""
FEISHU_DELIVERY_HINT=""

mkdir -p "$PROFILE_DIR/local"
_hd_load_distribution_config "$MANIFEST"
GIT_REMOTE="${REMOTE:-}"

_feishu_channel_configured() {
  if [[ -n "${FEISHU_HOME_CHANNEL:-}" ]]; then
    return 0
  fi
  if [[ ! -f "$ENV_FILE" ]]; then
    return 1
  fi
  python3 - "$ENV_FILE" <<'PY'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8")
for line in text.splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    m = re.match(r"^FEISHU_HOME_CHANNEL=(.*)$", line)
    if m and m.group(1).strip().strip('"').strip("'"):
        raise SystemExit(0)
raise SystemExit(1)
PY
}

_init_feishu_hint() {
  if ! _feishu_channel_configured; then
    FEISHU_DELIVERY_HINT=$'提示：未配置 FEISHU_HOME_CHANNEL，飞书通知可能无法送达。'
  fi
}

_write_cron_error_state() {
  local msg="$1"
  python3 - "$STATE_FILE" "$msg" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path

p = Path(sys.argv[1])
msg = sys.argv[2]
data = {}
if p.is_file():
    try:
        data = json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        data = {}
data["last_cron_error"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
data["last_cron_error_message"] = msg
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
}

_fail() {
  local msg="$1"
  if [[ -n "$FEISHU_DELIVERY_HINT" ]]; then
    msg="${msg}"$'\n\n'"${FEISHU_DELIVERY_HINT}"
  fi
  _write_cron_error_state "$msg"
  echo "[${PROFILE_NAME}] distribution 定时同步失败"
  echo "$msg"
  exit 1
}

_run_update() {
  local label="${1:-update}" output exit_code
  chmod +x "$UPDATE_CMD"
  set +e
  output="$("$UPDATE_CMD" 2>&1)"
  exit_code=$?
  set -e
  if [[ "$exit_code" -ne 0 ]]; then
    if [[ -z "${output// }" ]]; then
      output="（${label} 无输出，exit ${exit_code}）"
    fi
    _fail "${label} 失败 (exit ${exit_code})：
${output}"
  fi
  if [[ -n "$output" ]]; then
    printf '%s\n' "$output"
  fi
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

_write_state() {
  local sha="$1" version="$2" action="${3:-}"
  python3 - "$STATE_FILE" "$sha" "$version" "$action" <<'PY'
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
if sys.argv[4]:
    data["last_action"] = sys.argv[4]
for key in ("last_cron_error", "last_cron_error_message"):
    data.pop(key, None)
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

_init_feishu_hint

REMOTE_URL="$(_hd_resolve_remote_url "$MANIFEST" 2>/dev/null || true)"
if [[ -z "$REMOTE_URL" ]]; then
  _fail "未找到 distribution.yaml 中的 source"
fi

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
  _fail "无法访问远端 ${REMOTE_URL}"
fi

LOCAL_NEEDS_PUBLISH=false
if [[ -n "$LOCAL_DIRTY" ]] || [[ "${LOCAL_AHEAD:-0}" -gt 0 ]]; then
  LOCAL_NEEDS_PUBLISH=true
fi

UPDATE_CMD="$SKILL_SCRIPTS/update.sh"
PUBLISH_CMD="$SKILL_SCRIPTS/publish.sh"

# Conflict + pull: delegate to update.sh
if [[ "$LOCAL_NEEDS_PUBLISH" == true ]] && [[ "${REMOTE_AHEAD:-0}" -gt 0 ]]; then
  _run_update "分叉合并/拉取 (update.sh)"
  exit 0
fi

# Publish: local changes only, remote not ahead
if [[ "$LOCAL_NEEDS_PUBLISH" == true ]]; then
  PUBLISH_OUTPUT=""
  if ! PUBLISH_OUTPUT="$("$PUBLISH_CMD" 2>&1)"; then
    _fail "自动发布失败：
${PUBLISH_OUTPUT}"
  fi

  if echo "$PUBLISH_OUTPUT" | grep -q "^No changes to publish\."; then
    exit 0
  fi

  if ! echo "$PUBLISH_OUTPUT" | grep -q "Published ${PROFILE_NAME}@"; then
    _fail "自动发布失败：
${PUBLISH_OUTPUT}"
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
  _run_update "拉取远端更新 (update.sh)"
  exit 0
fi

# Silent: nothing to do (audit line for cron session records)
VERSION="$(_read_version)"
echo "[SILENT] ${PROFILE_NAME}@v${VERSION} — no distribution changes"
exit 0
