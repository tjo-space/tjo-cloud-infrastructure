echo "== Provision SSL certificate"
echo "DESEC_TOKEN=${DESEC_TOKEN}" >/etc/lego/secrets.env
systemctl start lego-run
systemctl enable lego-renew.timer

echo "=== Setup Barman"
sudo -u postgres createuser --superuser --replication barman || true
sudo -u barman barman receive-wal --create-slot local || true
sudo -u barman barman switch-wal local --force --archive --archive-timeout 30 || true
systemctl enable --now barman-cron.timer
systemctl enable --now barman-backup.timer
