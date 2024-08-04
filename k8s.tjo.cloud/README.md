# `k8s.tjo.cloud`

## Kubernetes JWT
For federation to work, the OIDC JWKS needs to be manually added in to id.tjo.space.

```
kubectl get --raw /openid/v1/jwks
````
