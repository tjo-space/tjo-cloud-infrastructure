#!/bin/bash
set -eou pipefail

opkg update
opkg install parted tune2fs resize2fs

parted --fix /dev/vda resizepart 2 100%
mount -o remount,ro /

tune2fs -O^resize_inode /dev/vda2
fsck.ext4 -y -f /dev/vda2

mount -o remount,rw /

resize2fs /dev/vda2

reboot
