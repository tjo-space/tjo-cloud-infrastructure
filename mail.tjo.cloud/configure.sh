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
  git sparse-checkout set --no-cone /mail.tjo.cloud
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
rsync -a mail.tjo.cloud/root/ /
systemctl daemon-reload

echo "=== Prepare srv directories"
mkdir -p /srv/data/stalwart
mkdir -p /srv/data/roundcube
mkdir -p /srv/data/caddy

echo "=== Secrets public key"
cat /etc/age/key.txt | grep "public key:"
echo "=== Read Secrets"
age -d -i /etc/age/key.txt mail.tjo.cloud/secrets.env.encrypted >mail.tjo.cloud/secrets.env
set -a && source mail.tjo.cloud/secrets.env && set +a

echo "=== Setup notify-webhook"
mkdir -p /etc/notify
echo "${WEBHOOK_URL}" >/etc/notify/webhook-url

echo "=== Setup stalwart"
systemctl restart stalwart

echo "=== Setup roundcube"
echo <<EOF >/etc/roundcube/secrets.env
ROUNDCUBE_MAIL_DB_PASSWORD=${POSTGRESQL_PASSWORD}
EOF
systemctl restart roundcube

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
} >>/etc/default/alloy
systemctl enable --now alloy
systemctl restart alloy

echo "=== Setup Caddy"
systemctl restart caddy

echo "=== Configure Restic"
echo "${BACKUP_PASSWORD}" >/etc/restic/restic.password
restic-helper cat config >/dev/null || restic-helper init
systemctl enable --now restic-backup.timer
systemctl enable --now restic-check.timer

echo "=== Configure UFW"
ufw default deny incoming
ufw default allow outgoing

ufw allow 22   # SSH
ufw allow 25   # EMAIL
ufw allow 110  # EMAIL
ufw allow 143  # EMAIL
ufw allow 443  # HTTPS
ufw allow 465  # EMAIL
ufw allow 587  # EMAIL
ufw allow 993  # EMAIL
ufw allow 995  # EMAIL
ufw allow 4190 # EMAIL
ufw --force enable
systemctl enable --now ufw
