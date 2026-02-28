#!/bin/bash
set -eou pipefail

echo "- OPKG Update"
opkg update

echo "- Tools"
opkg install tcpdump htop

echo "- Qemu agent"
opkg install qemu-ga

echo "- Installing Bird (BGP, Router Advertisement NDP)"
# Fixme: Upgrading to bird3 failed with:
#  daemon.crit bird: Assertion 'DG_IS_LOCKED(orig->domain)' failed at lib/resource.c:208
#opkg install bird3 bird3c
opkg remove bird3c bird3
opkg install bird2 bird2c

echo "- Installing unbound (DNS, DNS64)"
opkg install luci-app-unbound unbound-control adblock
opkg remove --autoremove dnsmasq odhcpd odhcpd-ipv6only

echo "- Reloading Services"
service bird reload
service network reload
sleep 5
service firewall reload
service unbound reload
service adblock reload

echo "- Done!"
