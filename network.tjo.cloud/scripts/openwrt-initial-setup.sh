#!/bin/bash
set -eou pipefail

opkg update

# QEMU
opkg install qemu-ga

# TAILSCALE
# Ref: https://github.com/adyanth/openwrt-tailscale-enabler/tree/v1.60.0-e428948-autoupdate
opkg install ca-bundle kmod-tun iptables-nft kmod-ipt-conntrack kmod-ipt-conntrack-extra kmod-ipt-conntrack-label kmod-ipt-nat kmod-nft-nat

wget https://github.com/adyanth/openwrt-tailscale-enabler/releases/download/v1.60.0-e428948-autoupdate/openwrt-tailscale-enabler-v1.60.0-e428948-autoupdate.tgz -o /tmp/tailscale-enabler.tgz

tar x -zvC / -f /tmp/tailscale-enabler.tgz

/etc/init.d/tailscale start
/etc/init.d/tailscale enable

tailscale up --advertise-routes=10.0.0.0/16,fd74:6a6f:0::/48 --accept-dns=false --ssh
