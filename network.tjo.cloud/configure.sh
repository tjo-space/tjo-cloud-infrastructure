#!/bin/bash
set -eou pipefail

echo "- OPKG Update"
opkg update

echo "- Configuring tailscale (Management Network)"
tailscale up \
  --advertise-routes=10.0.0.0/10,fd74:6a6f::/32,10.100.0.0/16,fd9b:7c3d:7f6a::/48 \
  --snat-subnet-routes=true \
  --accept-dns=false \
  --ssh \
  --reset

echo "- Installing Bird (BGP, Router Advertisement NDP)"
opkg install bird2 bird2c

echo "- Installing Kea (DHCPv4, DHCPv6)"
opkg install kea-dhcp4 kea-dhcp6 kea-uci kea-lfc
rm /etc/config/kea-opkg || true

echo "- Installing unbound (DNS, DNS64)"
opkg install luci-app-unbound unbound-control adblock
opkg remove --autoremove dnsmasq odhcpd odhcpd-ipv6only

echo "- Installing jool (NAT64)"
opkg install kmod-veth ip-full kmod-jool-netfilter jool-tools-netfilter
chmod +x /etc/jool/setup.sh
/etc/jool/setup.sh

echo "- Reloading Services"
service bird reload
service kea reload
service network reload
sleep 5
service firewall reload
service unbound reload
service adblock reload

echo "- Done!"
