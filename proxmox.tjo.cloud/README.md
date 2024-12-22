# `tjo-cloud/infrastructure`

## Proxmox Configuration

* [Guide to install on emmc](https://ibug.io/blog/2022/03/install-proxmox-ve-emmc/)

### 1. Tailscale.
Install and authenticate as always. Start with:

```
tailscale up --ssh --accept-routes --accept-dns=false --advertise-tags=tag:system-tjo-cloud --hostname=$(hostname -f | sed 's/\./-/g')

```

### 2. Install intel-firmware updates.

```
# Add non-free-firmware to the end
vim /etc/apt/sources.list

apt install intel-microcode

reboot
```

### 2. Configure Hosts.
Every Proxmox node needs to have configured `/etc/hosts` with entries for all servers.


#### Servers

```
100.71.223.89 naboo.system.tjo.cloud naboo
fd7a:115c:a1e0::8701:df59 naboo.system.tjo.cloud naboo

100.110.88.100 batuu.system.tjo.cloud batuu
fd7a:115c:a1e0::1901:5864 batuu.system.tjo.cloud batuu

100.103.129.84 endor.system.tjo.cloud endor
fd7a:115c:a1e0::3b01:8154 endor.system.tjo.cloud endor

100.67.200.27 jakku.system.tjo.cloud jakku
fd7a:115c:a1e0::301:c81b jakku.system.tjo.cloud jakku

100.82.48.119 nevaroo.system.tjo.cloud nevaroo
fd7a:115c:a1e0::b301:3077 nevaroo.system.tjo.cloud nevaroo

100.99.13.61 mustafar.system.tjo.cloud mustafar
fd7a:115c:a1e0::2601:d3d mustafar.system.tjo.cloud mustafar
```

### 3. Connect to Proxmox Cluster.

The `$EXISTING_CLUSTER_NODE_HOST_NAME` (examples: `nevaroo`, `jakku` not the FQDN) represent an existing cluster node, via which the new node will join to the cluster.

This node's ssh key (`cat ~/.ssh/id_rsa.pub`) must be added to the `$EXISTING_CLUSTER_NODE_HOST_NAME` under `~/.ssh/authorized_keys`.

Then the node can join the cluster using:

```
pvecm add $EXISTING_CLUSTER_NODE_HOST_NAME --link0 $(tailscale ip -4) --link1 $(tailscale ip -6)
```

### 4. Configure Firewall.

```
# Disable Web Portal on public IP
iptables -A INPUT -p tcp -i vmbr0 --dport 8006 -j DROP
```

### 5. Disable RPC Bind

```
systemctl disable --now rpcbind.target
systemctl disable --now rpcbind.socket
systemctl disable --now rpcbind.service
```

### 5. Disable SSH Access from public internet and enable public key auth.

Make sure to copy your public key using `ssh-copy-id root@proxmox.ip.address`.

```
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
```

### 6. Done

Your node should now be visible at https://proxmox.tjo.cloud.
