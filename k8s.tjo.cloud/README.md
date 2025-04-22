# `k8s.tjo.cloud`

**Links**:
 - [Dashboard](https://dashboard.k8s.tjo.cloud)
 - [Grafana](https://monitor.tjo.cloud/d/k8s_views_global/kubernetes-views-global)
 - [Argo](https://argocd.k8s.tjo.cloud/applications)

## Kubernetes JWT
For federation to work, the OIDC JWKS needs to be manually added in to id.tjo.space.

```
kubectl get --raw /openid/v1/jwks
````
