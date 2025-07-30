#!/bin/bash
set -euo pipefail

pushd "$(mktemp -d)"

echo "=== Installing Dependencies"
DEBIAN_FRONTEND=noninteractive apt update -y
DEBIAN_FRONTEND=noninteractive apt install -y \
  rsync \
  jq \
  age \
  gpg \
  git \
  ufw \
  barman \
  barman-cli \
  postgresql-16 \
  restic

echo "=== Grafana Alloy"
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor >/etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" >/etc/apt/sources.list.d/grafana.list
apt update -y
apt install -y alloy

echo "=== Lego"
LEGO_VERSION="v4.25.1"
LEGO_TMP_DIR=$(mktemp -d)
pushd "$LEGO_TMP_DIR"
curl -sL "https://github.com/go-acme/lego/releases/download/${LEGO_VERSION}/lego_${LEGO_VERSION}_linux_$(dpkg --print-architecture).tar.gz" | tar xvz --strip-components=1
install lego /usr/local/bin/lego
popd
rm -rf "$LEGO_TMP_DIR"

echo "=== Generating Age Key"
mkdir -p /etc/age
age-keygen -o /etc/age/key.txt

echo "=== Creating ssh key"
ssh-keygen -N "" -t ed25519 -f /root/.ssh/id_ed25519
ssh-keyscan -p 23 backup.tjo.cloud >>/root/.ssh/known_hosts
