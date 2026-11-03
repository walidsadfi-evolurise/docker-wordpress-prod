#!/bin/sh
# Restore a backup folder produced by backup/backup.sh.
# Usage: scripts/restore.sh <backup-dir> (a folder inside the `backups` volume, or a local copy)
set -eu
DIR="${1:?usage: restore.sh <backup-dir>}"
PASSPHRASE="$(cat secrets/backup_passphrase)"

echo "restore: verifying checksums"
( cd "${DIR}" && sha256sum -c SHA256SUMS )

echo "restore: database"
gpg --batch --yes --decrypt --passphrase "${PASSPHRASE}" "${DIR}/db.sql.gz.gpg" \
  | gunzip \
  | docker compose exec -T db sh -c 'mariadb -u"$MARIADB_USER" -p"$(cat $MARIADB_PASSWORD_FILE)" "$MARIADB_DATABASE"'

echo "restore: wp-content"
gpg --batch --yes --decrypt --passphrase "${PASSPHRASE}" "${DIR}/wp-content.tar.gz.gpg" \
  | docker compose exec -T php tar -C /var/www/html -xzf -

echo "restore: flushing caches"
docker compose exec -T nginx sh -c 'rm -rf /var/cache/nginx/*' || true
docker compose exec -T redis redis-cli FLUSHALL >/dev/null || true
echo "restore: done"
