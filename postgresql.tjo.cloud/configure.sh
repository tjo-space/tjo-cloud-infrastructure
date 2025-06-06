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

echo "== Configure Metadata"
SERVICE_NAME=$(jq -r ".service_name" /etc/tjo.cloud/meta.json)
SERVICE_VERSION=$(git describe --tags --always --dirty)
CLOUD_REGION=$(jq -r ".cloud_region" /etc/tjo.cloud/meta.json)

SERVICE_ACCOUNT_USERNAME=$(jq -r ".service_account.username" /etc/tjo.cloud/meta.json)
SERVICE_ACCOUNT_PASSWORD=$(jq -r ".service_account.password" /etc/tjo.cloud/meta.json)

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

echo "=== Configure Grafana Alloy"
ATTRIBUTES=""
ATTRIBUTES+="service.name=${SERVICE_NAME},"
ATTRIBUTES+="service.version=${SERVICE_VERSION},"
ATTRIBUTES+="cloud.region=${CLOUD_REGION}"
{
  echo ""
  echo "OTEL_RESOURCE_ATTRIBUTES=${ATTRIBUTES}"
  echo "ALLOY_USERNAME=${SERVICE_ACCOUNT_USERNAME}"
  echo "ALLOY_PASSWORD=${SERVICE_ACCOUNT_PASSWORD}"
  echo "ALLOY_POSTGRESQL_DATA_SOURCE=postgresql://admin:${POSTGRESQL_PASSWORD}@localhost:5432/admin?sslmode=disable"
} >>/etc/default/alloy
systemctl enable --now alloy
systemctl start alloy

echo "=== Setup Caddy"
systemctl start caddy

echo "=== Setup Postgresql"
cat <<EOF >/etc/postgresql/secrets.env
POSTGRES_PASSWORD=${POSTGRESQL_PASSWORD}
EOF
systemctl start postgresql

echo "=== Setup PgAdmin"
cat <<EOF >/etc/pgadmin/secrets.env
TJO_OAUTH2_CLIENT_ID=${TJO_OAUTH2_CLIENT_ID}
TJO_OAUTH2_CLIENT_SECRET=${TJO_OAUTH2_CLIENT_SECRET}
PGADMIN_DEFAULT_EMAIL=${PGADMIN_DEFAULT_EMAIL}
PGADMIN_DEFAULT_PASSWORD=${PGADMIN_DEFAULT_PASSWORD}
EOF
systemctl start pgadmin

echo "=== Setup Barman"
cat <<EOF >/etc/barman.d/local.conf
[local]
description = "Local Postgresql server"
streaming_archiver = on
streaming_conninfo = host=localhost user=admin dbname=admin password=${POSTGRESQL_PASSWORD}
conninfo = host=localhost user=admin dbname=admin password=${POSTGRESQL_PASSWORD}
slot_name = barman
create_slot = auto

compression = lz4

backup_directory = /srv/backup/postgresql
backup_compression = lz4
backup_method = postgres

retention_policy = RECOVERY WINDOW OF 2 WEEKS
minimum_redundancy = 7
last_backup_maximum_age = 1 WEEKS
EOF
systemctl start barman-cron.timer
systemctl start barman-backup.timer

echo "=== Configure UFW"
ufw default deny incoming
ufw default allow outgoing

ufw allow 22   # GIT
ufw allow 443  # HTTPS
ufw allow 5432 # POSTGRESQL

ufw --force enable
systemctl enable --now ufw
