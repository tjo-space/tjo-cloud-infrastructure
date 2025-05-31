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
