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
| ZeroTier Assignments | 10.1.0.0/16   | Use SLAAC/DHCP  |
| tealfleet.com        | 10.4.0.0/16   | fd74:6a6f:4::/48  |

Unspecified are unused.

### Layer 3
We do BGP Peering with other networks. This should also be counted as used.

See [k8s.tjo.cloud](../k8s.tjo.cloud/README.md) where the `10.100.0.0/16` and `fd9b:7c3d:7f6a::/48`
subnets are being used.

## network.tjo.cloud

### BGP

Each router instance establishes iBGP peering with all others.
ASN 65000 is used. Each router also listens for any iBGP peerings.
This is used for `k8s.tjo.cloud` where cilium advertises pod and external load balancer ips.

### DHCP Assignments
Ranges are `10.0.4.0-10.0.255.255` and `fd74:6a6f:0:400::-fd74:6a6f:0:ffff:ffff:ffff:ffff:ffff`.

### ZeroTier Assignments

Ranges are `10.1.0.0-10.0.255.255` and SLAAC for IPv6.

### Special designations
The `10.0.0.0/22` and `fd74:6a6f:0:0000::/54` are reserved for cloud operations.

| Use                   | IPv4             | IPv6                     |
|-----------------------|------------------|--------------------------|
| Primary Router LAN VIP        | 10.0.0.1/32      | fd74:6a6f::1/128   |
| # | # |  # |
| nevaroo.network.tjo.cloud | 10.0.0.4/10     | fd74:6a6f::4/128  |

# Setting up new Host

### 1. Add new device to terraform.tfvars.

### 3. Deploy terraform.

### 4. Set Password (see bitwarden)

### 5. Setup initial network.

```
# Fix: we want to use eth1.
# Remove all mentions of lan.
vim /etc/config/network
service network restart
```

### 5. Setup Tailscale.
Ref: https://github.com/adyanth/openwrt-tailscale-enabler

```
wget -O - https://code.tjo.space/tjo-cloud/infrastructure/raw/branch/main/network.tjo.cloud/scripts/openwrt-initial-setup.sh > initial.sh
sh initial.sh
```

### 6. Configure.

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
