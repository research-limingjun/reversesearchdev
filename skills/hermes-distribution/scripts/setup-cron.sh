#!/usr/bin/env bash
# Register 12h distribution bidirectional sync cron (no-agent + feishu).
# Cron script: profile/scripts/agent-sync-watchdog.sh (Hermes path requirement).
set -euo pipefail

SKILL_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$(cd "$SKILL_SCRIPTS/../../.." && pwd)"

# shellcheck source=_lib.sh
source "$SKILL_SCRIPTS/_lib.sh"

MANIFEST="$PROFILE_DIR/distribution.yaml"
_hd_load_distribution_config "$MANIFEST"

JOB_NAME="agent-distribution-sync"
SCRIPT_NAME="agent-sync-watchdog.sh"
JOBS_FILE="$PROFILE_DIR/cron/jobs.json"
WATCHDOG="$PROFILE_DIR/scripts/$SCRIPT_NAME"

cd "$PROFILE_DIR"
chmod +x "$WATCHDOG"

find_job_id() {
  python3 - "$JOBS_FILE" "$JOB_NAME" "$SCRIPT_NAME" <<'PY'
import json, sys
from pathlib import Path

p = Path(sys.argv[1])
name = sys.argv[2]
script = sys.argv[3]
legacy_names = {name, "dist-sync-12h"}
legacy_scripts = {script, "dist-sync-watchdog.sh"}
if not p.is_file():
    sys.exit(0)
try:
    jobs = json.loads(p.read_text())
except Exception:
    sys.exit(0)
if isinstance(jobs, dict):
    jobs = jobs.get("jobs", [])
for job in jobs:
    if job.get("name") in legacy_names or job.get("script") in legacy_scripts:
        print(job.get("id", ""))
        break
PY
}

JOB_ID="$(find_job_id)"

if [[ -n "$JOB_ID" ]]; then
  echo "→ Updating existing cron job: $JOB_ID ($JOB_NAME)"
  hermes -p "$PROFILE_NAME" cron edit "$JOB_ID" \
    --schedule "every 12h" \
    --no-agent \
    --script "$SCRIPT_NAME" \
    --deliver feishu \
    --name "$JOB_NAME" \
    --profile "$PROFILE_NAME"
else
  echo "→ Creating cron job: $JOB_NAME (every 12h → feishu)"
  hermes -p "$PROFILE_NAME" cron create "every 12h" \
    --no-agent \
    --script "$SCRIPT_NAME" \
    --deliver feishu \
    --name "$JOB_NAME" \
    --profile "$PROFILE_NAME"
fi

echo ""
echo "Done. Ensure gateway is running for scheduled ticks:"
echo "  hermes -p $PROFILE_NAME gateway start"
echo ""
echo "Manual test:"
echo "  hermes -p $PROFILE_NAME cron list"
echo "  hermes -p $PROFILE_NAME cron run <job_id>"
