#!/bin/sh
set -euo pipefail

# Ensure CRON_TIME is set (e.g. "0 4 * * *")
: "${CRON_TIME:?CRON_TIME must be provided}"

test -d /backups

# Dynamically write the crontab for Supercronic
cat > /app/crontab <<EOF
$CRON_TIME /opt/venv/bin/python /app/backup.py 
EOF

exec /opt/venv/bin/supercronic /app/crontab
