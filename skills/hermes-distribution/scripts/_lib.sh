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
