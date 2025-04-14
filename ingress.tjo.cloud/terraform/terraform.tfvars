nodes = {
  batuu = {
    id           = 800
    host         = "batuu"
    iso_storage  = "local"
    boot_storage = "local-nvme"

    ipv4_address = "10.0.16.10/20"
    ipv4_gateway = "10.0.16.1"
    ipv6_address = "fd74:6a6f:0:1010::1/64"
    ipv6_gateway = "fd74:6a6f:0:1000::1"
  }
  jakku = {
    id           = 801
    host         = "jakku"
    iso_storage  = "local"
    boot_storage = "local-nvme"

    ipv4_address = "10.0.32.10/20"
    ipv4_gateway = "10.0.32.1"
    ipv6_address = "fd74:6a6f:0:2010::1/64"
    ipv6_gateway = "fd74:6a6f:0:2000::1"
  }
  nevaroo = {
    id           = 802
    host         = "nevaroo"
    iso_storage  = "local"
    boot_storage = "local"

    ipv4_address = "10.0.48.10/20"
    ipv4_gateway = "10.0.48.1"
    ipv6_address = "fd74:6a6f:0:3010::1/64"
    ipv6_gateway = "fd74:6a6f:0:3000::1"
  }
  mustafar = {
    id           = 803
    host         = "mustafar"
    iso_storage  = "local"
    boot_storage = "local"

    ipv4_address = "10.0.64.10/20"
    ipv4_gateway = "10.0.64.1"
    ipv6_address = "fd74:6a6f:0:4010::1/64"
    ipv6_gateway = "fd74:6a6f:0:4000::1"
  }
}

ssh_keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICXAlzwziqfUUb2qmFwNF/nrBYc5MNT1MMOx81ohBmB+ tine@little.sys.tjo.space"
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
  "backup.tjo.cloud"             = { to = "u409586.your-storagebox.de", type = "CNAME" }
}
