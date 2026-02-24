#!/bin/bash
set -eou pipefail

echo "- OPKG Update"
opkg update

echo "- Resize FS"
if [ ! -f /etc/resized-fs.01.ok ]; then
  opkg install parted tune2fs resize2fs

  parted --fix /dev/vda resizepart 2 100%
  mount -o remount,ro /

  tune2fs -O^resize_inode /dev/vda2
  fsck.ext4 -y -f /dev/vda2

  mount -o remount,rw /
  touch /etc/resized-fs.01.ok
  reboot
fi
if [ ! -f /etc/resized-fs.02.ok ]; then
  resize2fs /dev/vda2
  touch /etc/resized-fs.02.ok
fi

echo "- Tailscale"
opkg install tailscale
tailscale up \
  --reset \
  --accept-dns=false \
  --ssh=true \
  --advertise-routes="10.0.0.0/10,fd74:6a6f::/32,10.100.0.0/16,fd9b:7c3d:7f6a::/48" \
  --accept-routes=false \
  --snat-subnet-routes=true \
  --advertise-exit-node \
  --advertise-tags="tag:network-tjo-cloud"

echo "- Qemu agent"
opkg install qemu-ga

echo "- Installing Bird (BGP, Router Advertisement NDP)"
# Fixme: Upgrading to bird3 failed with:
#  daemon.crit bird: Assertion 'DG_IS_LOCKED(orig->domain)' failed at lib/resource.c:208
#opkg install bird3 bird3c
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

echo "- Installing Yggdrasil"
opkg install yggdrasil luci-proto-yggdrasil yggdrasil-jumper

echo "- Reloading Services"
service bird reload
service kea reload
service network reload
sleep 5
service firewall reload
service unbound reload
service adblock reload

echo "- Done!"
