# mail.tjo.cloud

An mail cluster used for other `tjo.cloud` and `tjo.space` services as well personal email.

### Endpoints

- https://mail.tjo.cloud
  - SMTP, JMAP, management etc.
- https://web-mail.tjo.cloud
  - Web Email access.

### Components

- Debian
- Valkey
  - Cache for Stalwart
- Stalwart
  - Email server.
- Grafana Alloy
  - Metrics and Logs being shipped to https://monitor.tjo.cloud.
- Roundcube deployed on k8s.tjo.cloud.
  - Web Email access.
