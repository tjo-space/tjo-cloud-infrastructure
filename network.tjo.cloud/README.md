# `network.tjo.cloud`

Handling networking between nodes and between virtual machines.

# Architecture

<img align="left" src="docs/arhitecture.excalidraw.svg" width="40%">

__WAN interface__ either represents an actual public interface (on Hetzner) or an interface in home LAN that has port-forwarded ports to it from home router.

__LAN interface__ is an ordinary lan network.

__network.tjo.cloud__ establishes ZeroTier connection between other network.tjo.cloud nodes to establish Layer2 SD-WAN.

# Subnets

- network.tjo.cloud where `fd74:6a6f::/32` and `2a01:4f8:120:7700::/56` subnets are used.
- [k8s.tjo.cloud](../k8s.tjo.cloud/README.md) where the `fd9b:7c3d:7f6a::/48` subnet are being used.

## network.tjo.cloud

### BGP

Each router instance establishes iBGP peering with all others.
ASN 65000 is used. Each router also listens for any iBGP peerings.
This is used for `k8s.tjo.cloud` where cilium advertises pod and external load balancer ips.

### Subnets

| Node           | Internal            | Public                 |
|----------------|---------------------|------------------------|
| nevaroo-gateway        | fd74:6a6f:0:0::/64  | 2a01:4f8:120:7700::/64 |
| #              | #                   | #                      |
| nevaroo-router          | fd74:6a6f:0:10::/64 | 2a01:4f8:120:7710::/64 |
| endor-router          | fd74:6a6f:0:11::/64 | 2a01:4f8:120:7711::/64 |
| batuu-router          | fd74:6a6f:0:12::/64 | 2a01:4f8:120:7712::/64 |
| jakku-router          | fd74:6a6f:0:13::/64 | 2a01:4f8:120:7713::/64 |
| mustafar-router       | fd74:6a6f:0:14::/64 | 2a01:4f8:120:7714::/64 |
| #              | #                   | #                      |
| router/gateway VIP  | fd74:6a6f:0:53::/64 | # |
| nevaroo-gateway NAT64  | fd74:6a6f:0:64::/64 | 2a01:4f8:120:7764::/64 |

The `nevaroo-gateway` node is special gateway node. This once routes traffic out to the internet
and it has the public `/56` routed to it.

Any node in the "cloud" (hetzner cloud etc.) as well as "router" vms are part of the `nevaroo` subnets.

### Special designations

| Use                   | IPv4             | IPv6                     |
|-----------------------|------------------|--------------------------|
| nevaroo.network.tjo.cloud        | 10.0.0.1/32      | fd74:6a6f::1/128   |
| # | # |  # |
| nevaroo-router.network.tjo.cloud | #     | fd74:6a6f::10/128  |
| endor-router.network.tjo.cloud | #     | fd74:6a6f::11/128  |
| batuu-router.network.tjo.cloud | #     | fd74:6a6f::12/128  |
| jakku-router.network.tjo.cloud | #     | fd74:6a6f::13/128  |
| mustafar-router.network.tjo.cloud | #     | fd74:6a6f::14/128  |
| # | # |  # |
| endor.proxmox.tjo.cloud | 10.0.0.61/10     | fd74:6a6f::61/128  |
| batuu.proxmox.tjo.cloud | 10.0.0.62/10     | fd74:6a6f::62/128  |
| jakku.proxmox.tjo.cloud | 10.0.0.63/10     | fd74:6a6f::63/128  |
| nevaroo.proxmox.tjo.cloud | 10.0.0.64/10     | fd74:6a6f::64/128  |
| mustafar.proxmox.tjo.cloud | 10.0.0.65/10     | fd74:6a6f::65/128  |

# Setting up new Host

### 1. Add new device to terraform.tfvars.

### 2. Deploy terraform.

### 3. Configure.

```
# 1. Manually configure /etc/config/{firewall,network} to get ip and allow ssh
# 2. Then do the changes in the `prepare.sh` file manually.
# 3. Finally, run the configure.

just configure <node>
```

# TODO

## Use gitops for tailscale ACL.

 - [ ] Current version is an snapshot in time, more as an example then actual version used.

## Selfhost Zerotier.

 - [ ] Use [ztnet](https://github.com/sinamics/ztnet).
 - [ ] Deploy an instance on hetzner cloud. Same as it was done for id.tjo.cloud.
