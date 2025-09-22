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
  git sparse-checkout set --no-cone /s3.tjo.cloud
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
CLOUD_PROVIDER=$(jq -r ".cloud_provider" /etc/tjo.cloud/meta.json)
GARAGE_KIND=$(jq -r ".garage.kind" /etc/tjo.cloud/meta.json)
GARAGE_ZONE=$(jq -r ".garage.zone" /etc/tjo.cloud/meta.json)
GARAGE_SIZE=$(jq -r ".garage.size" /etc/tjo.cloud/meta.json)

SERVICE_ACCOUNT_USERNAME=$(jq -r ".service_account.username" /etc/tjo.cloud/meta.json)
SERVICE_ACCOUNT_PASSWORD=$(jq -r ".service_account.password" /etc/tjo.cloud/meta.json)

ZEROTIER_PUBLIC_KEY=$(jq -r ".zerotier.public_key" /etc/tjo.cloud/meta.json)
ZEROTIER_PRIVATE_KEY=$(jq -r ".zerotier.private_key" /etc/tjo.cloud/meta.json)

echo "== Configure zerotier"
if [ "${CLOUD_PROVIDER}" == "hetzner-cloud" ]; then
  echo "=== Enabling"
  systemctl stop zerotier-one.service || true
  echo "${ZEROTIER_PUBLIC_KEY}" >/var/lib/zerotier-one/identity.public
  echo "${ZEROTIER_PRIVATE_KEY}" >/var/lib/zerotier-one/identity.secret
  systemctl start zerotier-one.service
  sleep 5
  zerotier-cli join b6079f73c6379990
else
  echo "=== Disabling"
  systemctl disable --now zerotier-one.service
fi

echo "== Copy Configuration Files"
rsync -a s3.tjo.cloud/root/ /
systemctl daemon-reload

echo "== Configure Grafana Alloy"
ATTRIBUTES=""
ATTRIBUTES+="service.name=${SERVICE_NAME},"
ATTRIBUTES+="service.version=${SERVICE_VERSION},"
ATTRIBUTES+="cloud.region=${CLOUD_REGION},"
ATTRIBUTES+="cloud.provider=${CLOUD_PROVIDER}"
{
  echo ""
  echo "OTEL_RESOURCE_ATTRIBUTES=${ATTRIBUTES}"
  echo "ALLOY_USERNAME=${SERVICE_ACCOUNT_USERNAME}"
  echo "ALLOY_PASSWORD=${SERVICE_ACCOUNT_PASSWORD}"
} >>/etc/default/alloy
systemctl enable --now alloy
systemctl restart alloy

echo "== Configure Caddy"
if [ "${GARAGE_KIND}" == "gateway" ]; then
  echo "=== Enabling"
  systemctl restart caddy
  systemctl enable --now caddy
else
  echo "=== Disabling"
  systemctl disable --now caddy
fi

echo "== Configure Garage"
systemctl restart garage
systemctl enable --now garage

echo "== Configure UFW"
ufw default deny incoming
ufw default allow outgoing

ufw allow 80  # HTTP for CADDY
ufw allow 443 # HTTPS for CADDY

ufw allow 2222 # SSH MANAGEMENT ACCESS

ufw --force enable
systemctl enable --now ufw
