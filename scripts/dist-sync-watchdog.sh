#!/usr/bin/env bash
# Check remote distribution repo for updates; profile update + Feishu notify via cron stdout.
# Register: ./scripts/setup-dist-sync-cron.sh
set -euo pipefail

PROFILE_NAME="${PROFILE_NAME:-reversesearchdev}"
PROFILE_DIR="${HERMES_HOME:-$HOME/.hermes/profiles/$PROFILE_NAME}"
STATE_FILE="$PROFILE_DIR/local/dist_sync_state.json"
MANIFEST="$PROFILE_DIR/distribution.yaml"
PUBLISH_CONFIG="$PROFILE_DIR/publish.config"
BRANCH="${BRANCH:-main}"

cd "$PROFILE_DIR"
mkdir -p "$PROFILE_DIR/local"

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

if re.match(r"^github\.com/[\w.-]+/[\w.-]+/?$", url):
    url = f"https://{url.rstrip('/')}"
elif url.startswith("git@github.com:"):
    url = "https://github.com/" + url.split(":", 1)[1].removesuffix(".git")

print(url)
PY
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
  local sha="$1" version="$2"
  python3 - "$STATE_FILE" "$sha" "$version" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path

p = Path(sys.argv[1])
data = {
    "last_remote_sha": sys.argv[2],
    "last_version": sys.argv[3],
    "last_sync_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
}
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

_has_unpublished_local_changes() {
  [[ -d .git ]] || return 1
  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    return 0
  fi
  local local_sha remote_sha
  local_sha="$(git rev-parse HEAD 2>/dev/null || true)"
  remote_sha="$(git ls-remote origin "refs/heads/$BRANCH" 2>/dev/null | awk '{print $1}' | head -1)"
  if [[ -n "$local_sha" && -n "$remote_sha" && "$local_sha" != "$remote_sha" ]]; then
    return 0
  fi
  return 1
}

REMOTE_URL="$(_resolve_remote_url)" || {
  echo "[${PROFILE_NAME}] distribution 同步失败: 未找到 source/REMOTE" >&2
  exit 1
}

LS_URL="$(_normalize_ls_remote_url "$REMOTE_URL")"
REMOTE_SHA="$(git ls-remote "$LS_URL" "refs/heads/$BRANCH" 2>/dev/null | awk '{print $1}' | head -1)"

if [[ -z "$REMOTE_SHA" ]]; then
  echo "[${PROFILE_NAME}] distribution 同步失败: 无法访问远端 $LS_URL" >&2
  exit 1
fi

LAST_SHA="$(_read_state_sha)"
if [[ "$REMOTE_SHA" == "$LAST_SHA" ]]; then
  exit 0
fi

if _has_unpublished_local_changes; then
  cat <<EOF
[${PROFILE_NAME}] 远端数字人配置有更新，但本机有未发布改动，已跳过自动同步。
请先在本机执行 ./publish.sh 发布，或 git stash 后再手动执行:
  hermes -p ${PROFILE_NAME} profile update ${PROFILE_NAME} -y
远端: ${REMOTE_URL}
EOF
  exit 0
fi

if ! hermes -p "$PROFILE_NAME" profile update "$PROFILE_NAME" -y >/dev/null 2>&1; then
  echo "[${PROFILE_NAME}] profile update 失败，请检查 source 与 Git 权限" >&2
  exit 1
fi

NEW_VERSION="$(_read_version)"
_write_state "$REMOTE_SHA" "$NEW_VERSION"

cat <<EOF
[${PROFILE_NAME}] 数字人配置已自动更新至 v${NEW_VERSION}
来源: ${REMOTE_URL}
已同步: SOUL.md / skills / distribution.yaml（memories 与 .env 未改动）
EOF
