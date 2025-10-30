#!/usr/bin/env bash
set -eou pipefail
export DEBIAN_FRONTEND=noninteractive

##
# Folder2Ram
##
chmod +x /usr/sbin/folder2ram
folder2ram -enablesystemd
systemctl start folder2ram_startup.service
systemctl start folder2ram_shutdown.service
systemctl start folder2ram-sync.timer

##
# APT non-free-firmware
##
apt update -qq
apt install -qq -yy software-properties-common
apt-add-repository --component non-free-firmware --yes

# Intel microcode to fix CPU issues.
apt install -qq -yy intel-microcode

##
# FIREWALL
##
apt install -qq -yy ufw

ufw default deny incoming
ufw default allow outgoing
ufw default deny routed

# We allow SSH.
ufw allow 22

ufw allow in on tailscale0
ufw route allow in on vmbr0 out on vmbr0
ufw route allow in on vmbr1 out on vmbr1

ufw --force enable
systemctl enable --now ufw

##
# RPC BIND
##
systemctl disable --now rpcbind.target
systemctl disable --now rpcbind.socket
systemctl disable --now rpcbind.service

##
# SSH
##
echo "PasswordAuthentication no" >/etc/ssh/sshd_config.d/no-password-auth.conf

##
# Networking
# Ref: https://pve.proxmox.com/pve-docs/chapter-pvesdn.html#pvesdn_installation
##
apt install -qq -yy libpve-network-perl dnsmasq frr-pythontools

systemctl disable --now dnsmasq
# systemctl enable frr.service
# We do not yet use this, lets disable for now.
systemctl disable --now frr.service

# Disable IPv6 SLAAC/DHCPv6 on vmbr1.
#  Otherwise Proxmox Host will receive IP from the
#  network.tjo.cloud VM's.
cat <<EOF >/etc/network/interfaces.d/vmbr1.conf
iface vmbr1 inet manual
iface vmbr1 inet6 manual
  pre-up /sbin/sysctl -w net.ipv6.conf.vmbr1.autoconf=0
  pre-up /sbin/sysctl -w net.ipv6.conf.vmbr1.accept_ra=0
EOF
ip addr flush dev vmbr1
ip route flush dev vmbr1
ip -6 addr flush dev vmbr1
ip -6 route flush dev vmbr1
ifup vmbr1

##
# DNS
##
cat <<EOF >/etc/resolv.conf
# quad9
nameserver 9.9.9.9
nameserver 149.112.112.112
#nameserver 2620:fe::fe
#nameserver 2620:fe::9
# cloudflare (could not find better non-doh alternative)
nameserver 1.1.1.1
nameserver 1.0.0.1
#nameserver 2606:4700:4700::1111
#nameserver 2606:4700:4700::1001
EOF

##
# Restart PVE
##
systemctl restart pve-cluster.service
systemctl restart corosync.service

echo "=== Proxmox Prometheus Exporter"
apt install -qq -yy pipx
pipx install prometheus-pve-exporter
systemctl enable --now prometheus-pve-exporter.service

echo "=== Install Grafana Alloy"
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor >/etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" >/etc/apt/sources.list.d/grafana.list
apt update -y
apt install -y alloy
systemctl enable --now alloy
systemctl restart alloy
