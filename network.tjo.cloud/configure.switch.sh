#!/bin/bash
set -eou pipefail

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

echo "- OPKG Update"
opkg update

echo "- Qemu agent"
opkg install qemu-ga

echo "- Installing Bird (BGP, Router Advertisement NDP)"
opkg install bird2 bird2c

echo "- Installing unbound (DNS, DNS64)"
opkg install luci-app-unbound unbound-control adblock

echo "- Installing odhcpd and relayd"
opkg install dnsmasq odhcpd-ipv6only odhcp6c

echo "- Reloading Services"
service bird reload
service network reload
sleep 5
service firewall reload
service odhcpd reload
service unbound reload
service adblock reload

echo "- Done!"
