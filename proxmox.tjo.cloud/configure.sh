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
chown -R www-data:www-data /var/log/pveproxy

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
iface vmbr1 inet6 static
EOF

##
# DNS
##
cat <<EOF >/etc/resolv.conf
# dns0.eu
nameserver 193.110.81.0
nameserver 185.253.5.0
#nameserver 2a0f:fc80::
#nameserver 2a0f:fc81::
# quad9
nameserver 9.9.9.9
nameserver 149.112.112.112
#nameserver 2620:fe::fe
#nameserver 2620:fe::9
EOF

##
# Restart PVE
##
systemctl restart pve-cluster.service
systemctl restart corosync.service

##
# Proxmox Prometheus Exporter
##
apt install -qq -yy pipx
pipx install prometheus-pve-exporter
systemctl enable --now prometheus-pve-exporter.service
