# `network.tjo.cloud`

Handling networking between nodes and between virtual machines.

# Architecture

<img align="left" src="docs/arhitecture.excalidraw.svg" width="40%">

__WAN interface__ either represents an actual public interface (on Hetzner) or an interface in home LAN that has port-forwarded ports to it from home router.

__LAN interface__ is an ordinary lan network.

__ingress.tjo.cloud__ has port-forwarded all public ports to it (22, 25, 80, 443, 587 etc.). No other internal service is accessible from the internet.

__network.tjo.cloud__ establishes ZeroTier connection between other network.tjo.cloud nodes to establish Layer2 SD-WAN.

# Subnet
We are using `10.0.0.0/10` range for IPv4 as well as `fd74:6a6f::/32` for IPv6.
This is used for the whole SD-WAN.

It is further split as:

| Use                | IPv4          | IPv6              |
|--------------------|---------------|-------------------|
| network.tjo.cloud  | 10.0.0.0/16   | fd74:6a6f:0::/48  |
| tealfleet.com      | 10.4.0.0/16   | fd74:6a6f:4::/48  |
| k8s.tjo.cloud      | 10.8.0.0/16   | fd74:6a6f:8::/48  |

Unspecified are unused.

## network.tjo.cloud

### BGP

Each router instance establishes iBGP peering with all others.
ASN 65000 is used. Each router also listens on `10.0.0.1` for
any iBGP peerings. This is used for `k8s.tjo.cloud` where cilium advertises
pod and external load balancer ips.

### DHCP
DHCP Ranges are `10.0.4.0-10.0.255.255` and `fd74:6a6f:0:400::-fd74:6a6f:0:ffff:ffff:ffff:ffff:ffff`.

### Special designations
The `10.0.0.0/22` and `fd74:6a6f:0:0000::/54` are reserved for cloud operations.

| Use                   | IPv4             | IPv6                     |
|-----------------------|------------------|--------------------------|
| Router LAN VIP        | 10.0.0.1/32      | fd74:6a6f:0:0001::/128   |
| # | # |  # |
| batuu.network.tjo.cloud | 10.0.1.1/10     | fd74:6a6f:0:0101::/48  |
| jakku.network.tjo.cloud | 10.0.1.2/10     | fd74:6a6f:0:0102::/48  |
| nevaroo.network.tjo.cloud | 10.0.1.3/10     | fd74:6a6f:0:0103::/48  |
| mustafar.network.tjo.cloud | 10.0.1.4/10     | fd74:6a6f:0:0104::/48  |
| endor.network.tjo.cloud | 10.0.1.5/10     | fd74:6a6f:0:0105::/48  |
| # | # | # |
| batuu.ingress.tjo.cloud | 10.0.2.1/16     | fd74:6a6f:0:0201::/64  |
| jakku.ingress.tjo.cloud | 10.0.2.2/16     | fd74:6a6f:0:0202::/64  |
| nevaroo.ingress.tjo.cloud | 10.0.2.3/16     | fd74:6a6f:0:0203::/64  |
| mustafar.ingress.tjo.cloud | 10.0.2.4/16     | fd74:6a6f:0:0204::/64  |
| endor.ingress.tjo.cloud | 10.0.2.5/16     | fd74:6a6f:0:0205::/64  |

## k8s.tjo.cloud

We use `10.8.0.0/16` and `fd74:6a6f:8::/48` subnets for Kubernetes.
We use BGP to advertise these routes (iBGP to network.tjo.cloud).

| Use              | IPv4             | IPv6                     |
|------------------|------------------|--------------------------|
| Pods             | 10.8.0.0/20     | fd74:6a6f:8:0000::/52        |
| Load Balanancers | 10.8.16.0/20    | fd74:6a6f:8:1000::/52   |
| _unused_         | xxx              | xxx                      |
| Services         | 10.8.252.0/22   | fd74:6a6f:8::3e80::/108 |

For Services we use last possible subnets.

# Setting up new Host

### 1. Add new device to terraform.tfvars.

### 2. Manually configure vmbr0 and use import to import it.

```
tofu import 'proxmox_virtual_environment_network_linux_bridge.vmbr0["nevaroo"]' nevaroo:vmbr0
```

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


### 7. Approve ZeroTier member.

https://my.zerotier.com/network/b6079f73c6379990

# TODO

## Use gitops for tailscale ACL.

 - [ ] Current version is an snapshot in time, more as an example then actual version used.

## IPv6 Connectivity.

 - [ ] As we assign private ipv6 addresses, we would have to ise ipv6 nat to translate those to real ipv6 addresses.
 - [ ] BGP IPv6 doesn't work with Cilium. Some configuration must be changed.

## Selfhost Zerotier.

 - [ ] Use [ztnet](https://github.com/sinamics/ztnet).
 - [ ] Deploy an instance on hetzner cloud. Same as it was done for id.tjo.cloud.
