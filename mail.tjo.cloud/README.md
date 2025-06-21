# mail.tjo.cloud

An mail cluster used for other `tjo.cloud` and `tjo.space` services as well personal email.

### Endpoints

- https://mail.tjo.cloud
  - SMTP, JMAP, management etc.
- https://web-mail.tjo.cloud
  - Web Email access.

### Components

- Ubuntu
- Podman
  - Container management, using Systemd.
- Stalwart Container
  - Email server.
- Authentik LDAP Outputs
  - Used for Stalwart LDAP Authentication.
- Grafana Alloy
  - Metrics and Logs being shipped to https://monitor.tjo.cloud.
- Roundcube deployed on k8s.tjo.cloud.
  - Web Email access.

### TODO

- [ ] UFW not working with Podman. What do?
