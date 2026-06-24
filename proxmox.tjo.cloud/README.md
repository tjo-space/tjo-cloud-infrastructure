# `proxmox.tjo.cloud`

## Proxmox Configuration

* [Guide to install on emmc](https://ibug.io/blog/2022/03/install-proxmox-ve-emmc/)
* [E1000 Driver Hang](https://forum.proxmox.com/threads/e1000-driver-hang.58284/page-8#post-390709)
    * Implemented via disable_network_offloading task.
* [R8169 Driver Hang](https://github.com/Tooelite/proxmox-realtek-r8169-fix/)
    * Implemented via disable_network_offloading task.

### 1. Tailscale.
Install and authenticate as always. Start with:

```
tailscale up \
    --ssh \
    --accept-routes \
    --accept-dns=false \
    --advertise-tags=tag:proxmox.cloud.internal \
    --hostname=$(hostname -f | sed 's/\./-/g')

```

### 2. Add Tailscale IPs to the config file.

The Tailscale IPv4 and IPv6 must be written to the `terraform/terraform.tfvars` file.

### 3. Configure the servers.

```
just proxmox apply
just proxmox configure my-server
```


### 4. Connect to Proxmox Cluster.

The `$EXISTING_CLUSTER_NODE_HOST_NAME` (examples: `nevaroo`, `jakku` not the FQDN) represent an existing cluster node, via which the new node will join to the cluster.

This node's ssh key (`cat ~/.ssh/id_rsa.pub`) must be added to the `$EXISTING_CLUSTER_NODE_HOST_NAME` under `~/.ssh/authorized_keys`.

Then the node can join the cluster using:

```
pvecm add $EXISTING_CLUSTER_NODE_HOST_NAME --link0 $(tailscale ip -4) --link1 $(tailscale ip -6)
```


### 7. Done

Your node should now be visible at https://proxmox.cloud.internal.
