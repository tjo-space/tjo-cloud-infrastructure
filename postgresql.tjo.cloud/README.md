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

### Upgrading

#### 1. Change version in tfvars

#### 2. Apply tofu and install/configure new version
```
just postgresql apply
just postgresql configure-all
```


#### 4. Upgrade to new version
SSH to instance.

```
# should show both versions running
pg_lsclusters

export OLD_VERSION=17
export NEW_VERSION=18

systemctl stop postgresql@$OLD_VERSION-main postgresql@$NEW_VERSION-main

sudo -u postgres /usr/lib/postgresql/$NEW_VERSION/bin/pg_upgrade \
    --old-datadir /srv/data/postgresql/$OLD_VERSION \
    --new-datadir /srv/data/postgresql/$NEW_VERSION \
    --old-bindir /usr/lib/postgresql/$OLD_VERSION/bin \
    --new-bindir /usr/lib/postgresql/$NEW_VERSION/bin \
    -o "-c config_file=/etc/postgresql/$OLD_VERSION/main/postgresql.conf -c shared_preload_libraries='vchord.so'" \
    -O "-c config_file=/etc/postgresql/$NEW_VERSION/main/postgresql.conf -c shared_preload_libraries='vchord.so'" \
    --link

# Modify the port number to 5432 in /etc/postgresql/$NEW_VERSION/main/postgresql.conf
vim /etc/postgresql/$NEW_VERSION/main/postgresql.conf

systemctl start postgresql@$NEW_VERSION-main
```

#### 5. Apply configuration again
```
just postgresql configure-all config-refresh
```

#### 6. Cleanup

```
# On the instance
pg_dropcluster $OLD_VERSION main
# Remove old version installation
sudo apt purge postgresql-$OLD_VERSION postgresql-client-$OLD_VERSION

# On barman remove old version backups
rm -rf /srv/data/barman/$INSTANCE-$OLD_VERSION
```
