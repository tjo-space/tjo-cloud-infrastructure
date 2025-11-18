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

### Server Kinds

#### `postgresql`

Postgresql cluster instances. Each instance is independent.

Instances are on different hosts so due to latency requirements when accessing postgresql.

#### `barman`

Single instance with access to all postgresql clusters. Centralized backups.

Has access on postgresql servers to:
 - postgres user `barman` for replication
 - ssh access to `postgres` user for restoration

 Restic is running only here. To archive barman created backups.

### Filesystem

- `/` is the os drive
- `/srv/data` is where we store postgresql data and backups.
