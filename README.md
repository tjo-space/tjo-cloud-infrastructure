# `tjo-cloud/infrastructure`

Complete configuration of `tjo.cloud`.

Each subfolder represent a project.

* [ca.tjo.cloud](ca.tjo.cloud/README.md)
  - Internal Certificate Authority.
* [dns.tjo.cloud](dns.tjo.cloud/README.md)
  - Internal DNS.
* [id.tjo.cloud](id.tjo.cloud/README.md)
  - Identity and Authorization.
* [ingress.tjo.cloud](ingress.tjo.cloud/README.md)
  - Exposing internal services to the public internet.
* [k8s.tjo.cloud](k8s.tjo.cloud/README.md)
  - Kubernetes Cluster.
* [mail.tjo.cloud](mail.tjo.cloud/README.md)
  - Mail Server.
* [monitor.tjo.cloud](monitor.tjo.cloud/README.md)
  - Grafana + Loki + Prometheus Monitoring Stack.
* [network.tjo.cloud](network.tjo.cloud/README.md)
  - Router + BGP + DHCP + RADV.
* [postgresql.tjo.cloud](postgresql.tjo.cloud/README.md)
  - Postgresql Clusters.
* [proxmox.tjo.cloud](proxmox.tjo.cloud/README.md)
  - Proxmox Cluster.
* [s3.tjo.cloud](s3.tjo.cloud/README.md)
  - S3 Compatible storage.

## Starting Guide

Make sure you have [Devbox](https://www.jetify.com/docs/devbox) installed.

```
git clone
just dependencies
just post-pull

# Do your changes

just pre-commit
git commit -m "feat: new awesome stuff"
git push
```

## Secrets

Secrets are encrypted with the public keys specified in the `age.keys` file.

Every file that is encrypted has suffix `.encrypted`. Alongside it there is also
an `.sha256sum` file which is used to compare non-encrypted content, to not re-encrypt
if the file has not changed.

In case new keys are added in `age.keys`. All files must be re-encrypted. That can be done by
running the following:

```
FORCE_ENCRYPTION=1 just encrypt-all
```
