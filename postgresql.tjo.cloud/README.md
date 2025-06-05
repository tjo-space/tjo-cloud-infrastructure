# postgresql.tjo.cloud

An PostgreSQL cluster used for other `tjo.cloud` and `tjo.space` services.

### Components

- Ubuntu
- Podman
  - Container management, using Systemd.
- PostgreSQL Container
- PgAdmin Container
  - For administration. Accessible at https://postgresql.tjo.cloud.
- Restic
  - Backup storage.
- Caddy
  - SSL Termination and reverse proxy for https://postgresql.tjo.cloud.

### Filesystem

- `/` is the os drive
- `/srv/data` is drive intended for primary database storage.
- `/srv/backup` is drive intended for local backups.
  - Before being uploaded to offsite with restic.
