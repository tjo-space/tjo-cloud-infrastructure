# monitor.tjo.cloud

A LGTM stack for monitoring of `tjo.cloud`, `tjo.space` and other services.

### Components

- Ubuntu
- Grafana
- Prometheus
- Loki
- Restic
  - Shipping backups to backup.tjo.cloud.
- Grafana Alloy
  - Self-monitoring

### Filesystem

- `/` is the os drive
- `/srv/data` is where we store data
