#!/bin/bash
set -eou pipefail

echo "- OPKG Update"
opkg update

echo "- Qemu agent"
opkg install qemu-ga

echo "- Installing Bird (BGP, Router Advertisement NDP)"
opkg remove --autoremove bird2c bird2
opkg install bird3 bird3c

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
