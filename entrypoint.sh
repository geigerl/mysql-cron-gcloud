#!/bin/sh
set -euo pipefail

# Ensure variables were set (in dockerfile/docker dompose env vars)
: "${CRON_TIME:?CRON_TIME must be provided}"
: "${TARGET_USER:?TARGET_USER must be provided}"
: "${TARGET_UID:?TARGET_UID must be provided}"
: "${TARGET_GID:?TARGET_GID must be provided}"
: "${GCLOUD_STORAGE_CREDENTIALS_SECRET_NAME:?GCLOUD_STORAGE_CREDENTIALS_SECRET_NAME must be provided}"


test -d /backups

CRONTAB_FILE=/app/crontab

# Dynamically write the crontab for Supercronic
cat > $CRONTAB_FILE <<EOF
$CRON_TIME /opt/venv/bin/python /app/backup.py 
EOF

# ensure secrets dir exists and is owned properly
MAPPED_SECRETS_DIR="/run/secrets_"
mkdir -m 755 -p ${MAPPED_SECRETS_DIR}
cp -a /run/secrets/* ${MAPPED_SECRETS_DIR}/
# user readonly
chmod 400 ${MAPPED_SECRETS_DIR}/*
chown ${TARGET_UID}:${TARGET_GID} ${MAPPED_SECRETS_DIR}/*

# variable expansion works as these are not "inner" variables
# if you need to use variables in the command itself, escape via \$VAR, only then
# the var expansion won't work when using single quotes
exec su ${TARGET_USER} -s /bin/sh -c "export GCLOUD_STORAGE_CREDENTIALS_PATH='${MAPPED_SECRETS_DIR}/${GCLOUD_STORAGE_CREDENTIALS_SECRET_NAME}' && /opt/venv/bin/supercronic '${CRONTAB_FILE}'"
