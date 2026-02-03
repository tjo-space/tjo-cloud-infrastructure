# `k8s.tjo.cloud`

**Links**:
 - [Dashboard](https://dashboard.k8s.tjo.cloud)
 - [Grafana](https://monitor.tjo.cloud/d/k8s_views_global/kubernetes-views-global)
 - [Argo](https://argocd.k8s.tjo.cloud/applications)


## Networking

We use `fd9b:7c3d:7f6a::/48` subnets for Kubernetes.
We use BGP to advertise these routes (iBGP to network.tjo.cloud).

| Use                | IPv6                     |
|--------------------------------------------|
| Pods              | fd9b:7c3d:7f6a:0000::/52        |
| Load Balanancers    | fd9b:7c3d:7f6a:1000::/52   |
| _unused_           | xxx                      |
| Services          | fd9b:7c3d:7f6a:3e80::/108 |

For Services we use last possible subnets.

## Kubernetes JWT
For federation to work, the OIDC JWKS needs to be manually added in to id.tjo.cloud.

```
kubectl get --raw /openid/v1/jwks
````

## Upgrade Process

References:
 - https://docs.siderolabs.com/kubernetes-guides/advanced-guides/upgrading-kubernetes#upgrading-kubernetes
 - https://docs.siderolabs.com/talos/v1.12/configure-your-talos-cluster/lifecycle-management/upgrading-talos

### Steps
- [ ] Run `just upgrade-talos v1.12.0`
- [ ] Run `just upgrade-kubernetes v1.35.0`
- [ ] Change Talos and/or Kubernetes versions in `main.tf`.
- [ ] Run `just apply`.

## Node removal steps
- [ ] Run `just remove nevaroo-orange-k8s-tjo-cloud`
- [ ] Remove node configuration from `main.tf`.
- [ ] Run `just apply`
