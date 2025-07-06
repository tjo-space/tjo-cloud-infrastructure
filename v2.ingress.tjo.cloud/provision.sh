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
  ufw

echo "== Install Grafana Alloy"
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor >/etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" >/etc/apt/sources.list.d/grafana.list
apt update -y
apt install -y alloy

echo "== Install Haproxy"
apt install -y --no-install-recommends software-properties-common
add-apt-repository -y ppa:vbernat/haproxy-3.2
apt install -y haproxy=3.2.\*

echo "== Configure SSH"
cat <<EOF >/etc/ssh/sshd_config.d/port-2222.conf
Port 2222
EOF
systemctl restart ssh

echo "=== Install zerotier"
curl -s https://install.zerotier.com | sudo bash
