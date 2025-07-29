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
git describe --tags --always --dirty >/etc/tjo.cloud/version.txt

SERVICE_NAME=$(jq -r ".service_name" /etc/tjo.cloud/meta.json)
SERVICE_VERSION=$(cat /etc/tjo.cloud/version.txt)
CLOUD_REGION=$(jq -r ".cloud_region" /etc/tjo.cloud/meta.json)

SERVICE_ACCOUNT_USERNAME=$(jq -r ".service_account.username" /etc/tjo.cloud/meta.json)
SERVICE_ACCOUNT_PASSWORD=$(jq -r ".service_account.password" /etc/tjo.cloud/meta.json)

echo "=== Copy Configuration Files"
rsync -a postgresql.tjo.cloud/root/ /
systemctl daemon-reload

echo "=== Prepare srv directories"
mkdir -p /srv/{data,backup}/postgresql
chown -R postgres:postgres /srv/data/postgresql
chown -R barman:barman /srv/backup/postgresql

echo "=== Secrets public key"
cat /etc/age/key.txt | grep "public key:"
echo "=== Read Secrets"
age -d -i /etc/age/key.txt postgresql.tjo.cloud/secrets.env.encrypted >postgresql.tjo.cloud/secrets.env
set -a && source postgresql.tjo.cloud/secrets.env && set +a

echo "=== Setup notify-webhook"
mkdir -p /etc/notify
echo "${WEBHOOK_URL}" >/etc/notify/webhook-url

echo "== Provision SSL certificate"
echo "DNSIMPLE_OAUTH_TOKEN=${DNSIMPLE_OAUTH_TOKEN}" >/etc/lego/secrets.env
systemctl run lego-run
systemctl enable lego-renew.timer

echo "=== Setup Postgresql"
# We must init the db first.
sudo -u postgres /usr/lib/postgresql/16/bin/initdb -D /srv/data/postgresql || true
systemctl enable --now postgresql@16-main
systemctl restart postgresql@16-main
# Wait for postgresql to be ready.
pg_isready >/dev/null
sudo -u postgres psql template1 --command="ALTER USER postgres with encrypted password '${POSTGRESQL_PASSWORD}';"

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
  echo "ALLOY_POSTGRESQL_DATA_SOURCE=postgresql://postgres:${POSTGRESQL_PASSWORD}@localhost:5432/postgres?sslmode=disable"
} >>/etc/default/alloy
systemctl enable --now alloy
systemctl restart alloy

echo "=== Setup Barman"
sudo -u postgres createuser --superuser --replication barman || true
sudo -u barman barman receive-wal --create-slot local || true
sudo -u barman barman switch-wal local --force --archive --archive-timeout 30 || true
systemctl enable --now barman-cron.timer
systemctl enable --now barman-backup.timer

echo "=== Configure Restic"
echo "${BACKUP_PASSWORD}" >/etc/restic/restic.password
restic-helper cat config >/dev/null || restic-helper init
systemctl enable --now restic-backup.timer
systemctl enable --now restic-check.timer

echo "=== Configure UFW"
ufw default deny incoming
ufw default allow outgoing

ufw allow 22   # SSH
ufw allow 5432 # POSTGRESQL

ufw --force enable
systemctl enable --now ufw
