#!/bin/sh
set -eu
: "${BACKUP_CRON:=0 3 * * *}"
echo "${BACKUP_CRON} /usr/local/bin/backup.sh >> /proc/1/fd/1 2>&1" > /etc/crontabs/root
echo "backup: scheduled '${BACKUP_CRON}' (UTC)"
exec crond -f -l 2
