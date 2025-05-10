#!/bin/bash
set -euo pipefail

SERVICE_DIR="/root/service"
mkdir -p ${SERVICE_DIR}
cd ${SERVICE_DIR}

echo "== Fetch Source Code (from git)"
# Clone if not yet cloned
if [ ! -d .git ]; then
  git clone \
    --depth 1 \
    --no-checkout \
    --filter=tree:0 \
    https://github.com/tjo-space/tjo-cloud-infrastructure.git .
  git sparse-checkout set --no-cone /postgresql.tjo.cloud
  git checkout
else
  git fetch --depth=1
  git reset --hard origin/main
fi

echo "=== Copy Configuration Files"
rsync -a postgresql.tjo.cloud/root/ /
systemctl daemon-reload

echo "=== Prepare srv directories"
mkdir -p /srv/postgresql/{data,backups}

echo "=== Setup Postgresql"
systemctl restart postgresql
systemctl start postgresql-backup.timer
