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
CLOUD_PROVIDER=$(jq -r ".cloud_provider" /etc/tjo.cloud/meta.json)

SERVICE_ACCOUNT_USERNAME=$(jq -r ".service_account.username" /etc/tjo.cloud/meta.json)
SERVICE_ACCOUNT_PASSWORD=$(jq -r ".service_account.password" /etc/tjo.cloud/meta.json)

ZEROTIER_PUBLIC_KEY=$(jq -r ".zerotier.public_key" /etc/tjo.cloud/meta.json)
ZEROTIER_PRIVATE_KEY=$(jq -r ".zerotier.private_key" /etc/tjo.cloud/meta.json)

echo "=== Configure zerotier"
systemctl stop zerotier-one.service || true
echo "${ZEROTIER_PUBLIC_KEY}" >/var/lib/zerotier-one/identity.public
echo "${ZEROTIER_PRIVATE_KEY}" >/var/lib/zerotier-one/identity.secret
systemctl start zerotier-one.service
sleep 5
zerotier-cli join b6079f73c6379990

echo "=== Copy Configuration Files"
rsync -a mail.tjo.cloud/root/ /
systemctl daemon-reload

echo "=== Secrets public key"
cat /etc/age/key.txt | grep "public key:"
echo "=== Read Secrets"
age -d -i /etc/age/key.txt mail.tjo.cloud/secrets.env.encrypted >mail.tjo.cloud/secrets.env
set -a && source mail.tjo.cloud/secrets.env && set +a

echo "=== Configure Authentik LDAP"
mkdir -p /etc/authentik
cat <<EOF >/etc/authentik/secrets.env
AUTHENTIK_TOKEN=${AUTHENTIK_TOKEN}
EOF
systemctl restart authentik-ldap

echo "=== Configure Valkey"
mkdir -p /opt/valkey
systemctl restart valkey

echo "=== Configure stalwart"
cat <<EOF >/etc/stalwart/secrets.env
POSTGRESQL_PASSWORD=${POSTGRESQL_PASSWORD}
SERVICE_ACCOUNT_USERNAME=${SERVICE_ACCOUNT_USERNAME}
SERVICE_ACCOUNT_PASSWORD=${SERVICE_ACCOUNT_PASSWORD}
PROMETHEUS_PASSWORD=${PROMETHEUS_PASSWORD}
EOF
export STALWART_VERSION="v0.15.1"
export STALWART_ARCH="$(arch)"
pushd "$(mktemp -d)"
for bin in "stalwart" "stalwart-cli"; do
  curl -sL "https://github.com/stalwartlabs/stalwart/releases/download/${STALWART_VERSION}/${bin}-${STALWART_ARCH}-unknown-linux-gnu.tar.gz" | tar xvz
  mv ${bin} /usr/local/bin/${bin}
  chmod +x /usr/local/bin/${bin}
done
popd
id -u stalwart &>/dev/null || useradd stalwart -s /usr/sbin/nologin --no-create-home --system --user-group
systemctl restart stalwart
systemctl enable --now stalwart

echo "=== Configure Grafana Alloy"
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
  echo "PROMETHEUS_PASSWORD=${PROMETHEUS_PASSWORD}"
} >>/etc/default/alloy
systemctl enable --now alloy
systemctl restart alloy
