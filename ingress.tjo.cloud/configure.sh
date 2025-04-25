#!/usr/bin/env bash
set -euo pipefail

##
echo "== Fetch Source Code (from git)"
# We store all initial configs in the /srv location
cd /srv
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
# Enter ingress directory
cd /srv/ingress.tjo.cloud

##
echo "== Configure Metadata"
SERVICE_NAME="ingress.tjo.cloud"
SERVICE_VERSION="$(git describe --tags --always --dirty)"
CLOUD_REGION="$(hostname -s)"

SERVICE_ACCOUNT_USERNAME=$(jq -r ".service_account.username" /etc/tjo.cloud/meta.json)
SERVICE_ACCOUNT_PASSWORD=$(jq -r ".service_account.password" /etc/tjo.cloud/meta.json)

TAILSCALE_AUTH_KEY=$(jq -r ".tailscale.auth_key" /etc/tjo.cloud/meta.json)

DNSIMPLE_TOKEN=$(jq -r ".dnsimple.token" /etc/tjo.cloud/meta.json)

##
echo "== Install Dependencies"
apt update -y
apt install -y \
  gpg \
  git \
  ufw \
  nginx \
  nginx-extras \
  libnginx-mod-http-geoip2 \
  libnginx-mod-stream-geoip2

# Grafana Alloy
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor >/etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" >/etc/apt/sources.list.d/grafana.list
apt update -y
apt install -y alloy

# Tailscale
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg >/usr/share/keyrings/tailscale-archive-keyring.gpg
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list >/etc/apt/sources.list.d/tailscale.list
apt update -y
apt install -y tailscale

##
echo "== Configure Grafana Alloy"
cp -r root/etc/alloy/* /etc/alloy/
cp -r root/etc/default/alloy /etc/default/alloy
# Set Attributes
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

##
echo "== Configure Dyndns"
cp root/etc/systemd/system/dyndns.service /etc/systemd/system/dyndns.service
cp root/usr/local/bin/dyndns /usr/local/bin/dyndns
cp -r root/etc/default/dyndns /etc/default/dyndns
{
  echo ""
  echo "DNSIMPLE_TOKEN=${DNSIMPLE_TOKEN}"
  echo "CLOUD_REGION=${CLOUD_REGION}"
} >>/etc/default/dyndns
systemctl enable --now dyndns
systemctl restart dyndns

##
echo "== Configure Tailscale"
systemctl enable --now tailscaled
if tailscale status --json | jq -e -r '.BackendState != "Running"' >/dev/null; then
  tailscale up \
    --ssh=true \
    --accept-dns=false \
    --advertise-tags="tag:ingress-tjo-cloud" \
    --hostname="$(hostname -f | sed 's/\./-/g')" \
    --authkey="${TAILSCALE_AUTH_KEY}"
else
  echo "Tailscale is already running"
fi

##
echo "== Configure SSH"
cat <<EOF >/etc/ssh/sshd_config.d/port-2222.conf
Port 2222
EOF
systemctl restart ssh

##
echo "== Configure UFW"
# Should basically match nginx.conf
ufw default deny incoming
ufw default allow outgoing

ufw allow in on tailscale0

ufw allow 22   # GIT
ufw allow 25   # EMAIL
ufw allow 143  # EMAIL
ufw allow 443  # HTTPS
ufw allow 465  # EMAIL
ufw allow 587  # EMAIL
ufw allow 993  # EMAIL
ufw allow 1337 # HTTP (healthcheck)
ufw allow 4190 # EMAIL
ufw allow 6443 # KUBERNETES API

ufw allow 2222 # SSH ACCESS

ufw --force enable
systemctl enable ufw

##
echo "== Configure NGINX"
cp assets/dbip-city-lite-2023-07.mmdb /var/geoip.mmdb
cp -r root/etc/nginx/* /etc/nginx/
unlink /etc/nginx/sites-enabled/default || true
systemctl enable --now nginx
systemctl reload nginx
