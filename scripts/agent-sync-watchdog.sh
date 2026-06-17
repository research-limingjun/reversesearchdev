#!/usr/bin/env bash
# Bidirectional distribution sync: auto-publish local changes, pull remote updates, Feishu via cron stdout.
# Register: skills/hermes-distribution/scripts/setup-cron.sh
# Hermes cron requires script under profile/scripts/.
set -euo pipefail

PROFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_SCRIPTS="$PROFILE_DIR/skills/hermes-distribution/scripts"
PROFILE_NAME="${PROFILE_NAME:-reversesearchdev}"

export PROFILE_NAME
export HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

exec "$SKILL_SCRIPTS/agent-sync-watchdog-core.sh"
