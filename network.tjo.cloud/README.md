# `network.tjo.cloud`

Handling networking between nodes and between virtual machines.

# Architecture

<img align="left" src="docs/arhitecture.excalidraw.svg" width="40%">

__WAN interface__ either represents an actual public interface (on Hetzner) or an interface in home LAN that has port-forwarded ports to it from home router.

__LAN interface__ is an ordinary lan network.

__network.tjo.cloud__ establishes ZeroTier connection between other network.tjo.cloud nodes to establish Layer2 SD-WAN.

# Subnet

### Layer 2
We are using `10.0.0.0/10` range for IPv4 as well as `fd74:6a6f::/32` for IPv6 for L2 Network.


| Use                  | IPv4          | IPv6              |
|----------------------|---------------|-------------------|
| DHCP/SLAAC Assignments     | 10.0.0.0/16   | fd74:6a6f:0::/48  |
| ZeroTier Assignments | 10.1.0.0/16   | Use SLAAC  |

Unspecified are unused.

### Layer 3
We do BGP Peering with other networks. This should also be counted as used.

See [k8s.tjo.cloud](../k8s.tjo.cloud/README.md) where the `fd9b:7c3d:7f6a::/48` subnet are being used.

## network.tjo.cloud

### BGP

Each router instance establishes iBGP peering with all others.
ASN 65000 is used. Each router also listens for any iBGP peerings.
This is used for `k8s.tjo.cloud` where cilium advertises pod and external load balancer ips.

### DHCP Assignments
Ranges are `10.0.4.0-10.0.255.255`.

### ZeroTier Assignments

Ranges are `10.1.0.0-10.0.255.255` and SLAAC for IPv6.

### Special designations
The `10.0.0.0/22` and `fd74:6a6f:0:0000::/54` are reserved for cloud operations.

| Use                   | IPv4             | IPv6                     |
|-----------------------|------------------|--------------------------|
| nevaroo.network.tjo.cloud        | 10.0.0.1/32      | fd74:6a6f::1/128   |
| # | # |  # |
| endor.network.tjo.cloud | 10.0.0.11/10     | fd74:6a6f::11/128  |
| batuu.network.tjo.cloud | 10.0.0.12/10     | fd74:6a6f::12/128  |
| jakku.network.tjo.cloud | 10.0.0.13/10     | fd74:6a6f::13/128  |
| nevaroo.network.tjo.cloud | 10.0.0.14/10     | fd74:6a6f::14/128  |
| mustafar.network.tjo.cloud | 10.0.0.15/10     | fd74:6a6f::15/128  |
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

Once tailscale is up and manually configured (see the config files for guide).
We can use automated way of maintaining config.

```
just configure <node>
```


# TODO

## Use gitops for tailscale ACL.

 - [ ] Current version is an snapshot in time, more as an example then actual version used.

## Selfhost Zerotier.

 - [ ] Use [ztnet](https://github.com/sinamics/ztnet).
 - [ ] Deploy an instance on hetzner cloud. Same as it was done for id.tjo.cloud.
