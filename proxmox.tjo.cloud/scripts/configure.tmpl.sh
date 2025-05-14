#!/usr/bin/env bash
set -eou pipefail
export DEBIAN_FRONTEND=noninteractive

# {{ $nodes := (ds "nodes").nodes }}

##
# Folder2Ram
##
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
# /etc/hosts
##
cat <<EOF >/etc/hosts
127.0.0.1 localhost.localdomain localhost
::1       localhost.localdomain localhost ip6-localhost ip6-loopback
fe00::0   ip6-localnet
ff00::0   ip6-mcastprefix
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters
ff02::3   ip6-allhosts


{{- range $key, $value := $nodes }}
# {{ $key }}
{{ $value.ipv4 }} {{ $key }}.system.tjo.cloud {{ $key }}
# We have issues with IPv6
#{{ $value.ipv6 }} {{ $key }}.system.tjo.cloud {{ $key }}
{{ end }}
EOF

##
# FIREWALL
##
# Disable Web Portal on public IP
iptables -A INPUT -p tcp -i vmbr0 --dport 8006 -j DROP

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
