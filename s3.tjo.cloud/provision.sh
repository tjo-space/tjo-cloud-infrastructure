#!/bin/bash
set -euo pipefail

pushd "$(mktemp -d)"

echo "=== Installing Dependencies"
DEBIAN_FRONTEND=noninteractive apt update -y
DEBIAN_FRONTEND=noninteractive apt install -y \
  rsync \
  jq \
  gpg \
  git \
  curl \
  age \
  ufw

echo "== Install Grafana Alloy"
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor >/etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" >/etc/apt/sources.list.d/grafana.list
apt update -y
apt install -y alloy

echo "== Install Caddy"
apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg
chmod o+r /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install caddy

echo "== Configure SSH"
cat <<EOF >/etc/ssh/sshd_config.d/port-2222.conf
Port 2222
EOF
systemctl restart ssh

echo "=== Install zerotier"
curl -s https://install.zerotier.com | sudo bash

echo "=== Generating Age Key"
mkdir -p /etc/age
age-keygen -o /etc/age/key.txt
