# s3.tjo.cloud

S3 compatible storage service and static website hosting.

### Components

- Ubuntu
- UFW Firewall
- Zerotier (SD-WAN)
- Caddy
  - Handling TLS termination, dynamic certificate provisioning.
- Grafana Alloy
  - Metrics and Logs being shipped to https://monitor.tjo.cloud.
- Garage
  - S3 compatible storage service.
