# postgresql.tjo.cloud

An PostgreSQL cluster used for other `tjo.cloud` and `tjo.space` services.

### Components

- Ubuntu
- PostgreSQL
- PgBarman
  - Managing Postgresql Backups.
- Restic
  - Shipping backups to https://backup.tjo.cloud.
- Podman
  - Container management, using Systemd.
- PgAdmin Container
  - For administration. Accessible at https://postgresql.tjo.cloud.
- Caddy Container
  - SSL Termination and reverse proxy for https://postgresql.tjo.cloud.
- Grafana Alloy
  - Metrics and Logs being shipped to https://monitor.tjo.cloud.

### Filesystem

- `/` is the os drive
- `/srv/data` is drive intended for primary database storage.
- `/srv/backup` is drive intended for local backups.
  - Before being uploaded to offsite with restic.
