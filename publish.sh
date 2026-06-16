#!/usr/bin/env bash
# Publish reversesearchdev Hermes profile distribution to a git remote.
#
# Usage:
#   ./publish.sh                # reads publish.config, auto-bumps version
#   ./publish.sh <REMOTE>       # override remote
#   ./publish.sh --dry-run      # preview without bump/commit/push
set -euo pipefail

PROFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROFILE_DIR"

DRY_RUN=false
REMOTE=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h|--help)
      echo "Usage: $0 [REMOTE] [--dry-run]"
      echo "  REMOTE      Git remote URL (default: publish.config)"
      echo "  --dry-run   Preview staged files; no version bump or push"
      exit 0
      ;;
    *)
      if [[ -z "$REMOTE" ]]; then
        REMOTE="$arg"
      fi
      ;;
  esac
done

if [[ -z "$REMOTE" && -f "$PROFILE_DIR/publish.config" ]]; then
  # shellcheck source=/dev/null
  source "$PROFILE_DIR/publish.config"
fi

BRANCH="${BRANCH:-main}"

if [[ -z "${REMOTE:-}" && "$DRY_RUN" != true ]]; then
  echo "Error: no git remote. Set REMOTE in publish.config or pass as argument." >&2
  exit 1
fi

if [[ ! -f "$PROFILE_DIR/distribution.yaml" ]]; then
  echo "Error: distribution.yaml not found" >&2
  exit 1
fi

if [[ ! -f "$PROFILE_DIR/publish.config" ]]; then
  echo "Error: publish.config not found. Create it with REMOTE=..." >&2
  exit 1
fi

if [[ ! -d .git ]]; then
  echo "→ Initializing git repository (branch: $BRANCH)"
  git init -b "$BRANCH"
fi

_set_source() {
  local remote="$1"
  python3 - "$PROFILE_DIR/distribution.yaml" "$remote" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
remote = sys.argv[2].strip()
text = path.read_text(encoding="utf-8")
line = f"source: {remote}"

if re.search(r"^source:", text, re.M):
    text = re.sub(r"^source:\s*.+$", line, text, count=1, flags=re.M)
else:
    if re.search(r"^version:", text, re.M):
        text = re.sub(r"^(version:\s*.+)$", r"\1\n" + line, text, count=1, flags=re.M)
    else:
        text = line + "\n" + text

path.write_text(text, encoding="utf-8")
PY
}

_manifest_py() {
  python3 - "$PROFILE_DIR/distribution.yaml" "$1" <<'PY'
import re
import sys
from pathlib import Path

action = sys.argv[2]  # read | bump
path = Path(sys.argv[1])

try:
    import yaml
except ImportError:
    yaml = None

text = path.read_text(encoding="utf-8")

def parse_version(raw: str) -> str:
    return str(raw or "0.1.0").strip().lstrip("v")

def bump_patch(version: str) -> str:
    parts = parse_version(version).split(".")
    while len(parts) < 3:
        parts.append("0")
    parts[2] = str(int(parts[2]) + 1)
    return ".".join(parts[:3])

if yaml is not None:
    data = yaml.safe_load(text) or {}
else:
    data = {}
    m = re.search(r"^version:\s*['\"]?([^'\"\n]+)", text, re.M)
    if m:
        data["version"] = m.group(1).strip()
    owned = []
    in_owned = False
    for line in text.splitlines():
        if line.strip().startswith("distribution_owned:"):
            in_owned = True
            continue
        if in_owned:
            if line and not line[0].isspace():
                break
            m2 = re.match(r"\s*-\s+(.+)", line)
            if m2:
                owned.append(m2.group(1).strip().strip("'\""))
    data["distribution_owned"] = owned

version = parse_version(data.get("version", "0.1.0"))
owned = data.get("distribution_owned") or [
    "SOUL.md", "config.yaml", "distribution.yaml", "skills/"
]

if action == "bump":
    new_version = bump_patch(version)
    if re.search(r"^version:", text, re.M):
        text = re.sub(
            r"^version:\s*.+$",
            f"version: {new_version}",
            text,
            count=1,
            flags=re.M,
        )
    else:
        text = f"version: {new_version}\n" + text
    path.write_text(text, encoding="utf-8")
    version = new_version

print(version)
for p in owned:
    print(p)
PY
}

if [[ "$DRY_RUN" == true ]]; then
  VERSION="$(_manifest_py read | head -1)"
  echo "→ Dry run (version stays $VERSION; no bump)"
  MANIFEST_LINES=()
  while IFS= read -r line; do MANIFEST_LINES+=("$line"); done < <(_manifest_py read)
else
  if [[ -n "${REMOTE:-}" ]]; then
    echo "→ Writing source in distribution.yaml"
    _set_source "$REMOTE"
  fi
  echo "→ Bumping version in distribution.yaml"
  MANIFEST_LINES=()
  while IFS= read -r line; do MANIFEST_LINES+=("$line"); done < <(_manifest_py bump)
fi

VERSION="${MANIFEST_LINES[0]}"
OWNED_PATHS=("${MANIFEST_LINES[@]:1}")

if [[ -d .git ]]; then
  for secret in .env auth.json sessions memories; do
    if [[ -e "$secret" ]] && ! git check-ignore -q "$secret" 2>/dev/null; then
      echo "Error: $secret is not gitignored — aborting." >&2
      exit 1
    fi
  done
fi

ADD_PATHS=()
for p in "${OWNED_PATHS[@]}"; do
  if [[ -e "$p" || -d "$p" ]]; then
    ADD_PATHS+=("$p")
  else
    echo "Warning: path not found, skipping: $p" >&2
  fi
done

if [[ ${#ADD_PATHS[@]} -eq 0 ]]; then
  echo "Error: nothing to add." >&2
  exit 1
fi

echo "→ Staging (version: $VERSION)"
if [[ "$DRY_RUN" == true ]]; then
  git add --dry-run "${ADD_PATHS[@]}"
  echo ""
  echo "Dry run complete."
  exit 0
fi

_ensure_remote() {
  if git remote get-url origin &>/dev/null; then
    CURRENT_REMOTE=$(git remote get-url origin)
    if [[ "$CURRENT_REMOTE" != "$REMOTE" ]]; then
      git remote set-url origin "$REMOTE"
    fi
  else
    git remote add origin "$REMOTE"
  fi
}

_push_branch_and_tag() {
  echo "→ Pushing to origin/$BRANCH"
  git push -u origin "$BRANCH"

  TAG="v${VERSION}"
  git tag -f "$TAG"
  git push origin "refs/tags/$TAG" --force
}

git add "${ADD_PATHS[@]}"

if git diff --cached --quiet; then
  _ensure_remote
  git fetch origin "$BRANCH" --quiet 2>/dev/null || true
  LOCAL_AHEAD=$(git rev-list --count "origin/$BRANCH..HEAD" 2>/dev/null || echo 0)
  if [[ "$LOCAL_AHEAD" -gt 0 ]]; then
    echo "→ Pushing $LOCAL_AHEAD unpushed commit(s) to origin/$BRANCH"
    _push_branch_and_tag
    echo ""
    echo "Published reversesearchdev@${VERSION}"
    echo "  hermes profile install $REMOTE --name reversesearchdev --alias -y"
    echo "  hermes profile update reversesearchdev"
    exit 0
  fi
  echo "No changes to publish."
  exit 0
fi

STAGED_COUNT=$(git diff --cached --name-only | wc -l | tr -d ' ')
echo "→ Committing $STAGED_COUNT files as v${VERSION}"
git commit -m "v${VERSION}: reversesearchdev distribution"

_ensure_remote
_push_branch_and_tag

echo ""
echo "Published reversesearchdev@${VERSION}"
echo "  hermes profile install $REMOTE --name reversesearchdev --alias -y"
echo "  hermes profile update reversesearchdev"
