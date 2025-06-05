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
mkdir -p /srv/{data,backup}/postgresql

mkdir -p /srv/data/pgadmin
chown -R 5050:5050 /srv/data/pgadmin

mkdir -p /srv/data/caddy

echo "=== Secrets public key"
cat /etc/age/key.txt | grep "public key:"
echo "=== Read Secrets"
age -d -i /etc/age/key.txt postgresql.tjo.cloud/secrets.env.encrypted >postgresql.tjo.cloud/secrets.env
set -a && source postgresql.tjo.cloud/secrets.env && set +a

echo "=== Prepare Configurations"
cat <<EOF >/etc/postgresql/secrets.env
POSTGRES_PASSWORD=${POSTGRESQL_PASSWORD}
EOF
cat <<EOF >/etc/pgadmin/secrets.env
EOF

echo "=== Setup Caddy"
systemctl restart caddy

echo "=== Setup Postgresql"
systemctl restart postgresql
systemctl start postgresql-backup.timer

echo "=== Setup PgAdmin"
systemctl restart pgadmin
