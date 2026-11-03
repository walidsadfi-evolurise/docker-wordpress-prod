#!/bin/sh
# Dump the database and archive uploads, encrypt with a symmetric passphrase,
# keep N days locally, and (if configured) sync to an S3-compatible bucket.
set -eu

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="/backups/${STAMP}"
KEEP_DAYS="${BACKUP_KEEP_DAYS:-14}"
DB_PASSWORD="$(cat "${DB_PASSWORD_FILE}")"
PASSPHRASE="$(cat "${BACKUP_PASSPHRASE_FILE}")"

mkdir -p "${OUT}"
echo "backup: start ${STAMP}"

mariadb-dump --host="${DB_HOST}" --user="${DB_USER}" --password="${DB_PASSWORD}" \
  --single-transaction --quick --routines --triggers --no-tablespaces "${DB_NAME}" \
  | gzip -6 \
  | gpg --batch --yes --symmetric --cipher-algo AES256 --passphrase "${PASSPHRASE}" \
        -o "${OUT}/db.sql.gz.gpg"

tar -C /var/www/html -czf - wp-content/uploads wp-content/plugins wp-content/themes wp-content/mu-plugins 2>/dev/null \
  | gpg --batch --yes --symmetric --cipher-algo AES256 --passphrase "${PASSPHRASE}" \
        -o "${OUT}/wp-content.tar.gz.gpg"

sha256sum "${OUT}"/* > "${OUT}/SHA256SUMS"
du -sh "${OUT}" | sed 's/^/backup: size /'

# Local retention.
find /backups -mindepth 1 -maxdepth 1 -type d -mtime "+${KEEP_DAYS}" -exec rm -rf {} +

# Off-site copy.
if [ -n "${S3_BUCKET:-}" ]; then
  ENDPOINT_ARG=""
  [ -n "${S3_ENDPOINT:-}" ] && ENDPOINT_ARG="--endpoint-url ${S3_ENDPOINT}"
  # shellcheck disable=SC2086
  aws ${ENDPOINT_ARG} s3 cp "${OUT}" "s3://${S3_BUCKET}/${STAMP}/" --recursive --only-show-errors
  echo "backup: uploaded to s3://${S3_BUCKET}/${STAMP}/"
fi

echo "backup: done ${STAMP}"
