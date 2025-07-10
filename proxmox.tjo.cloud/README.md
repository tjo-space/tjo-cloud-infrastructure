# `proxmox.tjo.cloud`

## Proxmox Configuration

* [Guide to install on emmc](https://ibug.io/blog/2022/03/install-proxmox-ve-emmc/)
* [E1000 Driver Hand](https://forum.proxmox.com/threads/e1000-driver-hang.58284/page-8#post-390709)
  * `ethtool -K eno1 gso off gro off tso off tx off rx off rxvlan off txvlan off sg off`

### 1. Tailscale.
Install and authenticate as always. Start with:

```
tailscale up \
    --ssh \
    --accept-routes \
    --accept-dns=false \
    --advertise-tags=tag:system-tjo-cloud \
    --hostname=$(hostname -f | sed 's/\./-/g')

```

### 2. Add Tailscale IPs to the config file.

The Tailscale IPv4 and IPv6 must be written to the config/nodes.yaml file.

### 3. Configure the servers.

```
# When new server is added, all must be re-configured.
# To include hosts records for the new server.
just proxmox configure-all

# Or to configure single server
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

Your node should now be visible at https://proxmox.tjo.cloud.
