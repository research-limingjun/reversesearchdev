#!/usr/bin/env bash
# Register (or refresh) the 12h distribution sync cron job for reversesearchdev.
set -euo pipefail

PROFILE_NAME="${PROFILE_NAME:-reversesearchdev}"
PROFILE_DIR="${HERMES_HOME:-$HOME/.hermes/profiles/$PROFILE_NAME}"
JOB_NAME="dist-sync-12h"
SCRIPT_NAME="dist-sync-watchdog.sh"
JOBS_FILE="$PROFILE_DIR/cron/jobs.json"

cd "$PROFILE_DIR"
chmod +x "$PROFILE_DIR/scripts/$SCRIPT_NAME"

find_job_id() {
  python3 - "$JOBS_FILE" "$JOB_NAME" <<'PY'
import json, sys
from pathlib import Path

p = Path(sys.argv[1])
name = sys.argv[2]
if not p.is_file():
    sys.exit(0)
try:
    jobs = json.loads(p.read_text())
except Exception:
    sys.exit(0)
if isinstance(jobs, dict):
    jobs = jobs.get("jobs", [])
for job in jobs:
    if job.get("name") == name:
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
