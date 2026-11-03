#!/bin/sh
# First-run helper: creates .env from the example and generates secrets.
set -eu
cd "$(dirname "$0")/.."

[ -f .env ] || { cp .env.example .env; echo "init: .env created, edit SITE_HOST and ACME_EMAIL"; }
mkdir -p secrets
gen() { head -c 48 /dev/urandom | base64 | tr -d '/+=\n' | cut -c1-40; }
for s in db_password db_root_password backup_passphrase; do
  if [ ! -s "secrets/${s}" ]; then gen > "secrets/${s}"; echo "init: secrets/${s} generated"; fi
done
chmod 600 secrets/*
echo "init: done. Next: docker compose up -d --build"
