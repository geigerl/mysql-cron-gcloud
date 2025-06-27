#!/bin/sh
set -euo pipefail

# Ensure variables were set (in dockerfile/docker dompose env vars)
: "${CRON_TIME:?CRON_TIME must be provided}"
: "${GCLOUD_STORAGE_CREDENTIALS_PATH:?GCLOUD_STORAGE_CREDENTIALS_PATH must be provided}"

test -d /backups

CRONTAB_FILE=/app/crontab

# Dynamically write the crontab for Supercronic
cat > $CRONTAB_FILE <<EOF
$CRON_TIME /opt/venv/bin/python /app/backup.py 
EOF

exec /opt/venv/bin/supercronic "${CRONTAB_FILE}"
