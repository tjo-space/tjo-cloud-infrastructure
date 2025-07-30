# postgresql.tjo.cloud

An PostgreSQL cluster used for other `tjo.cloud` and `tjo.space` services.

### Components

- Ubuntu
- PostgreSQL
- PgBarman
  - Managing Postgresql Backups.
- Restic
  - Shipping backups to backup.tjo.cloud.
- PgAdmin
  - For administration. Accessible at https://postgresql.tjo.cloud.
  - Deployed on k8s.tjo.cloud.
- Grafana Alloy
  - Metrics and Logs being shipped to https://monitor.tjo.cloud.

### Filesystem

- `/` is the os drive
- `/srv/data` is drive intended for primary database storage.
- `/srv/backup` is drive intended for local backups.
  - Before being uploaded to offsite with restic.
