nodes = {
  batuu = {
    host         = "batuu"
    iso_storage  = "local"
    boot_storage = "local-nvme"
    ipv4         = "10.0.2.1/16"
    ipv6         = "fd74:6a6f:0:0201::/64"
  }
  jakku = {
    host         = "jakku"
    iso_storage  = "local"
    boot_storage = "local-nvme"
    ipv4         = "10.0.2.2/16"
    ipv6         = "fd74:6a6f:0:0202::/64"
  }
  nevaroo = {
    host         = "nevaroo"
    iso_storage  = "local"
    boot_storage = "local"
    ipv4         = "10.0.2.3/16"
    ipv6         = "fd74:6a6f:0:0203::/64"
  }
  mustafar = {
    host         = "mustafar"
    iso_storage  = "local"
    boot_storage = "local"
    ipv4         = "10.0.2.4/16"
    ipv6         = "fd74:6a6f:0:0204::/64"
  }
  endor = {
    host         = "endor"
    iso_storage  = "local"
    boot_storage = "local-nvme"
    ipv4         = "10.0.2.5/16"
    ipv6         = "fd74:6a6f:0:0205::/64"
  }
}

ssh_keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICXAlzwziqfUUb2qmFwNF/nrBYc5MNT1MMOx81ohBmB+ tine@little.sys.tjo.space",
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdKdeca1pqJfT5SbvbOVxjvGXdIny29gqRrQbrNht3m tine@Anas-MacBook-Pro.local",
]

zones = [
  "tjo.space",
  "tjo.cloud",
  # Used for automated A and AAAA records creation.
  "ingress.tjo.cloud",
]

records = {
  # TJO.SPACE
  "tjo.space"      = { to = "any.ingress.tjo.cloud" }
  "code.tjo.space" = { to = "any.ingress.tjo.cloud" }
  # mail.tjo.space requires specific ports to be accessible,
  # which is often not the case for home internet providers.
  # so we should only ever use "cloud" ingresses.
  "mail.tjo.space"      = { to = "nevaroo.ingress.tjo.cloud" }
  "paperless.tjo.space" = { to = "any.ingress.tjo.cloud" }
  "penpot.tjo.space"    = { to = "any.ingress.tjo.cloud" }
  "rss.tjo.space"       = { to = "any.ingress.tjo.cloud" }
  "search.tjo.space"    = { to = "any.ingress.tjo.cloud" }
  "send.tjo.space"      = { to = "any.ingress.tjo.cloud" }
  "status.tjo.space"    = { to = "tjo-space.github.io", type = "CNAME" }
  "stuff.tjo.space"     = { to = "any.ingress.tjo.cloud" }
  "vault.tjo.space"     = { to = "any.ingress.tjo.cloud" }
  "yt.tjo.space"        = { to = "any.ingress.tjo.cloud" }
  "books.tjo.space"     = { to = "any.ingress.tjo.cloud" }
  # CLOUD.TJO.SPACE
  "cloud.tjo.space"     = { to = "any.ingress.tjo.cloud" }
  "collabora.tjo.space" = { to = "any.ingress.tjo.cloud" }
  # CHAT.TJO.SPACE
  "chat.tjo.space"         = { to = "any.ingress.tjo.cloud" }
  "matrix.chat.tjo.space"  = { to = "any.ingress.tjo.cloud" }
  "webhook.chat.tjo.space" = { to = "any.ingress.tjo.cloud" }
  "turn.chat.tjo.space"    = { to = "any.ingress.tjo.cloud" }
  # MEDIA.TJO.SPACE
  "media.tjo.space"   = { to = "any.ingress.tjo.cloud" }
  "*.media.tjo.space" = { to = "any.ingress.tjo.cloud" }
  # TJO.CLOUD
  "grpc.otel.monitor.tjo.cloud"  = { to = "any.ingress.tjo.cloud" }
  "http.otel.monitor.tjo.cloud"  = { to = "any.ingress.tjo.cloud" }
  "loki.monitor.tjo.cloud"       = { to = "any.ingress.tjo.cloud" }
  "prometheus.monitor.tjo.cloud" = { to = "any.ingress.tjo.cloud" }
  "monitor.tjo.cloud"            = { to = "any.ingress.tjo.cloud" }
  "postgresql.tjo.cloud"         = { to = "any.ingress.tjo.cloud" }
  "proxmox.tjo.cloud"            = { to = "any.ingress.tjo.cloud" }
  "vault.tjo.cloud"              = { to = "any.ingress.tjo.cloud" }
  "dashboard.k8s.tjo.cloud"      = { to = "any.ingress.tjo.cloud" }
  "argocd.k8s.tjo.cloud"         = { to = "any.ingress.tjo.cloud" }
  "backup.tjo.cloud"             = { to = "u409586.your-storagebox.de", type = "CNAME" }
}
