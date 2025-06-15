# mail.tjo.cloud

An mail cluster used for other `tjo.cloud` and `tjo.space` services as well personal email.

### Components

- Ubuntu
- Podman
  - Container management, using Systemd.
- Caddy Container
  - SSL Termination and reverse proxy for https://mail.tjo.cloud.
- Stalwart Container
  - Email server.
- Grafana Alloy
  - Metrics and Logs being shipped to https://monitor.tjo.cloud.
- Restic
  - Shipping backups to https://backup.tjo.cloud.

### Filesystem

- `/` is the os drive
- `/srv/data` is drive intended for primary database storage.
- `/srv/backup` is drive intended for local backups.
  - Before being uploaded to offsite with restic.
