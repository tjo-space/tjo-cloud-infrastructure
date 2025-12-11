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
  git sparse-checkout set --no-cone /ingress.tjo.cloud
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

SERVICE_ACCOUNT_USERNAME=$(jq -r ".service_account.username" /etc/tjo.cloud/meta.json)
SERVICE_ACCOUNT_PASSWORD=$(jq -r ".service_account.password" /etc/tjo.cloud/meta.json)

ZEROTIER_PUBLIC_KEY=$(jq -r ".zerotier.public_key" /etc/tjo.cloud/meta.json)
ZEROTIER_PRIVATE_KEY=$(jq -r ".zerotier.private_key" /etc/tjo.cloud/meta.json)

echo "== Configure zerotier"
systemctl stop zerotier-one.service || true
echo "${ZEROTIER_PUBLIC_KEY}" >/var/lib/zerotier-one/identity.public
echo "${ZEROTIER_PRIVATE_KEY}" >/var/lib/zerotier-one/identity.secret
systemctl start zerotier-one.service
sleep 5
zerotier-cli join b6079f73c6379990

echo "== Copy Configuration Files"
rsync -a ingress.tjo.cloud/root/ /
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

echo "== Configure Routes"
sleep 5
# k8s.tjo.cloud
ip -4 route add 10.100.0.0/16 via 10.0.0.1 || true
ip -6 route add fd9b:7c3d:7f6a::/48 via fd74:6a6f::1 || true

echo "== Configure Haproxy"
systemctl restart haproxy
systemctl enable --now haproxy

echo "== Configure UFW"
ufw default deny incoming
ufw default allow outgoing

ufw allow 22  # SSH   for PROXY
ufw allow 80  # HTTP  for PROXY
ufw allow 443 # HTTPS for PROXY

ufw allow 1337 # HTTP (healthcheck)
ufw allow 2222 # SSH MANAGEMENT ACCESS

ufw --force enable
systemctl enable --now ufw
