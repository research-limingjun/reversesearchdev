#!/usr/bin/env bash
# Create distribution/Conflict_* branch on sync conflict; reset main; print Feishu-ready notice.
# Called by agent-sync-watchdog.sh when CONFLICT_STRATEGY=distribution_branch.
set -euo pipefail

PROFILE_NAME="${PROFILE_NAME:-reversesearchdev}"
PROFILE_DIR="${HERMES_HOME:-$HOME/.hermes/profiles/$PROFILE_NAME}"
STATE_FILE="$PROFILE_DIR/local/dist_sync_state.json"
MANIFEST="$PROFILE_DIR/distribution.yaml"
PUBLISH_CONFIG="$PROFILE_DIR/publish.config"
BRANCH="${BRANCH:-main}"
GIT_REMOTE=""
CONFLICT_STRATEGY="${CONFLICT_STRATEGY:-distribution_branch}"
CONFLICT_BRANCH_PREFIX="${CONFLICT_BRANCH_PREFIX:-distribution/Conflict}"

CONFLICT_LOCAL_DESC="${CONFLICT_LOCAL_DESC:-}"
CONFLICT_LOCAL_HEAD="${CONFLICT_LOCAL_HEAD:-}"
CONFLICT_REMOTE_HEAD="${CONFLICT_REMOTE_HEAD:-}"
CONFLICT_REMOTE_AHEAD="${CONFLICT_REMOTE_AHEAD:-0}"

cd "$PROFILE_DIR"

_load_publish_config() {
  if [[ -f "$PUBLISH_CONFIG" ]]; then
    # shellcheck source=/dev/null
    source "$PUBLISH_CONFIG"
  fi
  BRANCH="${BRANCH:-main}"
  GIT_REMOTE="${REMOTE:-}"
  CONFLICT_STRATEGY="${CONFLICT_STRATEGY:-distribution_branch}"
  CONFLICT_BRANCH_PREFIX="${CONFLICT_BRANCH_PREFIX:-distribution/Conflict}"
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

_read_conflict_state() {
  python3 - "$STATE_FILE" <<'PY'
import json, sys
from pathlib import Path

p = Path(sys.argv[1])
out = {"branch": "", "local_sha": "", "remote_sha": ""}
if not p.is_file():
    print(json.dumps(out))
    raise SystemExit(0)
try:
    data = json.loads(p.read_text(encoding="utf-8"))
except Exception:
    print(json.dumps(out))
    raise SystemExit(0)
out["branch"] = data.get("pending_conflict_branch") or ""
out["local_sha"] = data.get("pending_conflict_local_sha") or ""
out["remote_sha"] = data.get("pending_conflict_remote_sha") or ""
print(json.dumps(out))
PY
}

_write_conflict_state() {
  local branch="$1" local_sha="$2" remote_sha="$3"
  python3 - "$STATE_FILE" "$branch" "$local_sha" "$remote_sha" <<'PY'
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

data["pending_conflict_branch"] = sys.argv[2]
data["pending_conflict_local_sha"] = sys.argv[3]
data["pending_conflict_remote_sha"] = sys.argv[4]
data["pending_conflict_at"] = datetime.now(timezone.utc).isoformat(timespec="seconds")

p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
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

_generate_branch_name() {
  local host ts
  host="$(hostname -s 2>/dev/null || hostname)"
  host="$(echo "$host" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]//g' | cut -c1-20)"
  ts="$(date +%y.%m%d.%H%M.%S)"
  echo "${CONFLICT_BRANCH_PREFIX}_${BRANCH}_${host}_${ts}"
}

_github_compare_url() {
  local remote_url="$1" conflict_branch="$2"
  python3 - "$remote_url" "$BRANCH" "$conflict_branch" <<'PY'
import sys
from urllib.parse import quote

remote = sys.argv[1].strip()
base_branch = sys.argv[2]
head_branch = sys.argv[3]

if remote.startswith("git@github.com:"):
    path = remote.split(":", 1)[1].removesuffix(".git")
    repo = f"https://github.com/{path}"
elif remote.startswith("https://github.com/"):
    repo = remote.removesuffix(".git")
else:
    repo = remote.removesuffix(".git")

head_enc = quote(head_branch, safe="")
print(f"{repo}/compare/{base_branch}...{head_enc}?expand=1")
PY
}

_try_gh_pr_url() {
  local conflict_branch="$1"
  command -v gh &>/dev/null || return 1
  gh auth status &>/dev/null 2>&1 || return 1
  gh pr create \
    --base "$BRANCH" \
    --head "$conflict_branch" \
    --title "distribution sync conflict: ${conflict_branch##*/}" \
    --body "Auto-created by agent-conflict-branch.sh for ${PROFILE_NAME}." \
    2>/dev/null || return 1
}

_emit_fallback_notice() {
  local local_desc="$1" local_head="$2" remote_head="$3" remote_ahead="$4" remote_url="$5"
  cat <<EOF
[${PROFILE_NAME}] 配置同步冲突，需人工介入（冲突分支推送失败）
本机未发布: ${local_desc}
远端领先 ${remote_ahead} 个提交 (${local_head}..${remote_head})
建议:
  1) 手动创建分支并 push 后按 distribution 冲突流程合并
  2) 放弃本机改动: git stash && ./update.sh
远端: ${remote_url}
EOF
}

_emit_distribution_notice() {
  local conflict_branch="$1" local_changes="$2" compare_url="$3" pr_url="${4:-}"
  cat <<EOF
【Distribution】配置合并冲突通知

需求： ${PROFILE_NAME} 数字人配置同步
配置档： ${PROFILE_NAME}
Git项目： ${GIT_REMOTE}
目标分支： ${BRANCH}
冲突分支： ${conflict_branch}
本机改动： ${local_changes}

操作步骤：
1. 进入配置目录，拉取远端；确保无多余未提交改动
   cd ${PROFILE_DIR} && git fetch

2. 切换至冲突分支
   git checkout ${conflict_branch}

3. 合并目标分支（会提示 CONFLICT，请 Diff 后逐个解决；建议与冲突方研发沟通）
   git pull origin ${BRANCH} --no-rebase

4. 解决冲突后推送冲突分支
   git push origin ${conflict_branch}

5. 在 GitHub 发起合并（图形化界面，推荐）
   ${compare_url}
EOF
  if [[ -n "$pr_url" ]]; then
    echo "   PR: ${pr_url}"
  fi
  cat <<EOF

说明：本机 main 已恢复为远端最新，Agent 可继续运行；合并 PR 后其他机器将自动 pull。
EOF
}

_load_publish_config

REMOTE_URL="${GIT_REMOTE:-}"
if [[ -z "$REMOTE_URL" ]]; then
  REMOTE_URL="$(grep -E '^source:' "$MANIFEST" 2>/dev/null | sed 's/^source:[[:space:]]*//' | tr -d "'\"" || true)"
fi

LOCAL_HEAD="${CONFLICT_LOCAL_HEAD:-$(git rev-parse --short HEAD 2>/dev/null || echo unknown)}"
REMOTE_HEAD="${CONFLICT_REMOTE_HEAD:-$(git rev-parse --short "origin/$BRANCH" 2>/dev/null || echo unknown)}"
REMOTE_SHA="$(git rev-parse "origin/$BRANCH" 2>/dev/null || true)"

LOCAL_DESC="$CONFLICT_LOCAL_DESC"
if [[ -z "$LOCAL_DESC" ]]; then
  LOCAL_DESC="$(_list_owned_dirty | _join_lines || true)"
fi
if [[ -z "$LOCAL_DESC" ]]; then
  LOCAL_DESC="已 commit 未 push"
fi

_ensure_origin_remote "$GIT_REMOTE" || true

CONFLICT_JSON="$(_read_conflict_state)"
PENDING_BRANCH="$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['branch'])" "$CONFLICT_JSON")"
PENDING_LOCAL_SHA="$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['local_sha'])" "$CONFLICT_JSON")"
PENDING_REMOTE_SHA="$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['remote_sha'])" "$CONFLICT_JSON")"

CURRENT_LOCAL_SHA="$(git rev-parse HEAD 2>/dev/null || true)"

DIRTY_PATHS=()
while IFS= read -r p; do
  [[ -n "$p" ]] && DIRTY_PATHS+=("$p")
done < <(_list_owned_dirty)

if [[ ${#DIRTY_PATHS[@]} -gt 0 ]]; then
  git add "${DIRTY_PATHS[@]}"
  if ! git diff --cached --quiet; then
    git commit -m "WIP: distribution sync conflict ($(hostname -s 2>/dev/null || hostname))"
  fi
  CURRENT_LOCAL_SHA="$(git rev-parse HEAD)"
  LOCAL_DESC="$(_list_owned_dirty | _join_lines || true)"
  if [[ -z "$LOCAL_DESC" ]]; then
    LOCAL_DESC="$(git diff-tree --no-commit-id --name-only -r HEAD | _join_lines || echo "（见最近提交）")"
  fi
fi

if [[ -n "$PENDING_BRANCH" && "$PENDING_LOCAL_SHA" == "$CURRENT_LOCAL_SHA" && "$PENDING_REMOTE_SHA" == "$REMOTE_SHA" ]]; then
  if git ls-remote --exit-code origin "refs/heads/$PENDING_BRANCH" &>/dev/null; then
    COMPARE_URL="$(_github_compare_url "$GIT_REMOTE" "$PENDING_BRANCH")"
    _emit_distribution_notice "$PENDING_BRANCH" "$LOCAL_DESC" "$COMPARE_URL" ""
    exit 0
  fi
fi

CONFLICT_BRANCH="$(_generate_branch_name)"

if ! git branch "$CONFLICT_BRANCH" 2>/dev/null; then
  _emit_fallback_notice "$LOCAL_DESC" "$LOCAL_HEAD" "$REMOTE_HEAD" "$CONFLICT_REMOTE_AHEAD" "$REMOTE_URL"
  exit 0
fi

if ! git push -u origin "$CONFLICT_BRANCH" 2>&1; then
  git branch -D "$CONFLICT_BRANCH" 2>/dev/null || true
  _emit_fallback_notice "$LOCAL_DESC" "$LOCAL_HEAD" "$REMOTE_HEAD" "$CONFLICT_REMOTE_AHEAD" "$REMOTE_URL"
  exit 0
fi

git checkout "$BRANCH" 2>/dev/null || git checkout -B "$BRANCH"
git reset --hard "origin/$BRANCH"

_write_conflict_state "$CONFLICT_BRANCH" "$CURRENT_LOCAL_SHA" "$REMOTE_SHA"

COMPARE_URL="$(_github_compare_url "$GIT_REMOTE" "$CONFLICT_BRANCH")"
PR_URL="$(_try_gh_pr_url "$CONFLICT_BRANCH" || true)"

_emit_distribution_notice "$CONFLICT_BRANCH" "$LOCAL_DESC" "$COMPARE_URL" "$PR_URL"
