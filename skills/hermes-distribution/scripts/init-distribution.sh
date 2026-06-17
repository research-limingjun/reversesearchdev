#!/usr/bin/env bash
# Scaffold a new Hermes agent distribution profile.
#
# Usage:
#   init-distribution.sh <name>
#   init-distribution.sh --name <name> [--force]
set -euo pipefail

SKILL_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SKILL_SCRIPTS/.." && pwd)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
PROFILES_DIR="$HERMES_HOME/profiles"

FORCE=false
NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      NAME="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 <name> | --name <name> [--force]"
      exit 0
      ;;
    *)
      if [[ -z "$NAME" ]]; then
        NAME="$1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$NAME" ]]; then
  echo "Error: agent name required" >&2
  exit 1
fi

if [[ ! "$NAME" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
  echo "Error: invalid name '$NAME' (use letters, digits, _ -)" >&2
  exit 1
fi

PROFILE_DIR="$PROFILES_DIR/$NAME"

if [[ -e "$PROFILE_DIR" && "$FORCE" != true ]]; then
  echo "Error: profile already exists: $PROFILE_DIR (use --force to overwrite scaffold)" >&2
  exit 1
fi

mkdir -p "$PROFILE_DIR/scripts" "$PROFILE_DIR/local" "$PROFILE_DIR/skills"

cat > "$PROFILE_DIR/distribution.yaml" <<EOF
name: ${NAME}
version: 1.0.0
description: "Hermes agent distribution for ${NAME}"
hermes_requires: '>=0.16.0'
author: ""
license: internal
publish:
  branch: main
  conflict_strategy: distribution_branch
  conflict_branch_prefix: distribution/Conflict
env_requires: []
distribution_owned:
- SOUL.md
- config.yaml
- distribution.yaml
- skills
- scripts
- .gitignore
source:
EOF

cat > "$PROFILE_DIR/SOUL.md" <<'EOF'
# Agent Soul

Describe this agent's role, tone, and constraints here.
EOF

cat > "$PROFILE_DIR/config.yaml" <<'EOF'
# Hermes profile config (optional overrides)
EOF

cat > "$PROFILE_DIR/.env.EXAMPLE" <<'EOF'
# Copy to .env and fill in values (never commit .env)
# FEISHU_HOME_CHANNEL=oc_xxxxxxxx
EOF

cat > "$PROFILE_DIR/.gitignore" <<'EOF'
.env
auth.json
sessions/
memories/
local/
cron/
*.log
.DS_Store
EOF

# Bootstrap hermes-distribution skill
if [[ -d "$SKILL_ROOT" ]]; then
  rm -rf "$PROFILE_DIR/skills/hermes-distribution"
  cp -R "$SKILL_ROOT" "$PROFILE_DIR/skills/hermes-distribution"
fi

# Watchdog template for cron (must live in profile/scripts/)
cat > "$PROFILE_DIR/scripts/agent-sync-watchdog.sh" <<'WATCHDOG'
#!/usr/bin/env bash
# Bidirectional distribution sync (cron entry). Calls skill/scripts publish & update.
set -euo pipefail

PROFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_SCRIPTS="$PROFILE_DIR/skills/hermes-distribution/scripts"
PROFILE_NAME="${PROFILE_NAME:-__PROFILE_NAME__}"

export PROFILE_NAME
export HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

exec "$SKILL_SCRIPTS/agent-sync-watchdog-core.sh"
WATCHDOG

sed -i '' "s/__PROFILE_NAME__/${NAME}/g" "$PROFILE_DIR/scripts/agent-sync-watchdog.sh" 2>/dev/null || \
  sed -i "s/__PROFILE_NAME__/${NAME}/g" "$PROFILE_DIR/scripts/agent-sync-watchdog.sh"

chmod +x "$PROFILE_DIR/scripts/agent-sync-watchdog.sh"
chmod +x "$PROFILE_DIR/skills/hermes-distribution/scripts/"*.sh 2>/dev/null || true

cd "$PROFILE_DIR"
if [[ ! -d .git ]]; then
  git init -b main
  echo "→ Initialized git repo in $PROFILE_DIR"
fi

cat <<EOF

Scaffold created: $PROFILE_DIR

Next steps:
  1. Create an empty Git repository (if needed)
  2. Configure .env (see skills/hermes-distribution/references/env-setup.md)
  3. First publish:
     skills/hermes-distribution/scripts/publish.sh <git-remote-url>
  4. Optional 12h sync:
     skills/hermes-distribution/scripts/setup-cron.sh

EOF
