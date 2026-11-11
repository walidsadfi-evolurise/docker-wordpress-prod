#!/bin/sh
# No arguments: run the scheduler. With arguments (e.g. `backup.sh` for a one-off or a restore
# command): run them instead, so `docker compose run --rm backup backup.sh` works.
set -eu
if [ "$#" -gt 0 ]; then
  exec "$@"
fi
: "${BACKUP_CRON:=0 3 * * *}"
echo "${BACKUP_CRON} /usr/local/bin/backup.sh >> /proc/1/fd/1 2>&1" > /etc/crontabs/root
echo "backup: scheduled '${BACKUP_CRON}' (UTC)"
exec crond -f -l 2
