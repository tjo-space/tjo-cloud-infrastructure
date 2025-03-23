#!/bin/bash
set -eou pipefail

opkg update

# QEMU
opkg install qemu-ga

# TAILSCALE
opkg install ca-bundle kmod-tun iptables-nft kmod-ipt-conntrack kmod-ipt-conntrack-extra kmod-ipt-conntrack-label kmod-ipt-nat kmod-nft-nat

/etc/init.d/tailscale start
/etc/init.d/tailscale enable

tailscale up --advertise-routes=10.0.0.0/16,fd74:6a6f:0::/48 --accept-dns=false --ssh
