# How to resize Ext4 filesystem

1. Increase the Disk in Proxmox
2. `growpart /dev/vda 1`
3. `resize2fs /dev/vda1`
