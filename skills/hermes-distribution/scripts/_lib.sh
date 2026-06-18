#!/usr/bin/env bash
# Shared helpers: read profile settings from distribution.yaml.
set -euo pipefail

_hd_load_distribution_config() {
  local manifest="${1:?manifest path required}"
  if [[ ! -f "$manifest" ]]; then
    echo "Error: distribution.yaml not found: $manifest" >&2
    return 1
  fi
  eval "$(python3 - "$manifest" <<'PY'
import re
import shlex
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
data = {}
try:
    import yaml
    data = yaml.safe_load(text) or {}
except Exception:
    data = {}

def pick(key, pattern, default=""):
    if isinstance(data, dict) and data.get(key) not in (None, ""):
        return str(data[key]).strip()
    m = re.search(pattern, text, re.M)
    return m.group(1).strip().strip("'\"") if m else default

name = pick("name", r"^name:\s*['\"]?([^'\"\n]+)")
source = pick("source", r"^source:\s*['\"]?([^'\"\n]*)")
publish = data.get("publish") if isinstance(data, dict) else {}
if not isinstance(publish, dict):
    publish = {}
branch = str(publish.get("branch") or "main")
conflict_strategy = str(publish.get("conflict_strategy") or "distribution_branch")
conflict_prefix = str(publish.get("conflict_branch_prefix") or "distribution/Conflict")

def emit(key, val):
    print(f"export {key}={shlex.quote(str(val))}")

emit("PROFILE_NAME", name)
emit("GIT_REMOTE", source)
emit("REMOTE", source)
emit("BRANCH", branch)
emit("CONFLICT_STRATEGY", conflict_strategy)
emit("CONFLICT_BRANCH_PREFIX", conflict_prefix)
PY
)"
}

_hd_resolve_remote_url() {
  local manifest="$1"
  python3 - "$manifest" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
url = ""
try:
    import yaml
    data = yaml.safe_load(text) or {}
    url = (data.get("source") or "").strip()
except Exception:
    pass
if not url:
    m = re.search(r"^source:\s*['\"]?([^'\"\n]+)", text, re.M)
    url = m.group(1).strip() if m else ""
if not url:
    sys.exit(1)
print(url)
PY
}

_hd_git_merge_web_url() {
  local remote_url="$1" base_branch="$2" head_branch="$3"
  python3 - "$remote_url" "$base_branch" "$head_branch" <<'PY'
import sys
from urllib.parse import quote, urlencode

remote = sys.argv[1].strip()
base_branch = sys.argv[2]
head_branch = sys.argv[3]

HTTP_HOSTS = {"git.17usoft.com"}


def web_base(url: str) -> tuple[str, str]:
    """Return (web_base_url, host) for a git remote."""
    if url.startswith("git@"):
        host_path = url[4:]
        host, _, path = host_path.partition(":")
        path = path.removesuffix(".git")
        scheme = "http" if host in HTTP_HOSTS else "https"
        return f"{scheme}://{host}/{path}", host
    if url.startswith("http://") or url.startswith("https://"):
        base = url.removesuffix(".git")
        host = base.split("://", 1)[1].split("/", 1)[0]
        return base, host
    raise ValueError(f"unsupported git remote: {url}")


repo, host = web_base(remote)

if host == "github.com":
    head_enc = quote(head_branch, safe="")
    print(f"{repo}/compare/{base_branch}...{head_enc}?expand=1")
else:
    query = urlencode(
        {
            "merge_request[source_branch]": head_branch,
            "merge_request[target_branch]": base_branch,
        }
    )
    print(f"{repo}/-/merge_requests/new?{query}")
PY
}
