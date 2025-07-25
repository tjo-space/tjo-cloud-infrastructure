nodes_hetzner_cloud = {
  "pink" = {
    datacenter = "fsn1-dc14"
  }
}

ssh_keys = {
  "tine+pc"     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICXAlzwziqfUUb2qmFwNF/nrBYc5MNT1MMOx81ohBmB+ tine+pc@tjo.space"
  "tine+mobile" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdPg/nG/Qzk110SBukHHEDqH6/3IJHsIKKHWTrqjaOh tine+mobile@tjo.space"
  "tine+ipad"   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHrX2u82zWpVhjWng1cR4Kj76SajLJQ/Nmwd2GPaJpt1 tine+ipad@tjo.cloud"
  "tine+mac"    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdKdeca1pqJfT5SbvbOVxjvGXdIny29gqRrQbrNht3m tine+mac@tjo.space"
}

zones = [
  "tjo.space",
  "tjo.cloud",
]

records = {
  # TJO.SPACE
  "tjo.space"           = { to = "any.ingress.tjo.cloud" }
  "code.tjo.space"      = { to = "any.ingress.tjo.cloud" }
  "paperless.tjo.space" = { to = "any.ingress.tjo.cloud" }
  "penpot.tjo.space"    = { to = "any.ingress.tjo.cloud" }
  "rss.tjo.space"       = { to = "any.ingress.tjo.cloud" }
  "search.tjo.space"    = { to = "any.ingress.tjo.cloud" }
  "send.tjo.space"      = { to = "any.ingress.tjo.cloud" }
  "status.tjo.space"    = { to = "tjo-space.github.io", type = "CNAME" }
  "stuff.tjo.space"     = { to = "any.ingress.tjo.cloud" }
  "vault.tjo.space"     = { to = "any.ingress.tjo.cloud" }
  "books.tjo.space"     = { to = "any.ingress.tjo.cloud" }
  # CLOUD.TJO.SPACE
  "cloud.tjo.space"     = { to = "any.ingress.tjo.cloud" }
  "collabora.tjo.space" = { to = "any.ingress.tjo.cloud" }
  # CHAT.TJO.SPACE
  "chat.tjo.space"         = { to = "any.ingress.tjo.cloud" }
  "matrix.chat.tjo.space"  = { to = "any.ingress.tjo.cloud" }
  "webhook.chat.tjo.space" = { to = "any.ingress.tjo.cloud" }
  "turn.chat.tjo.space"    = { to = "any.ingress.tjo.cloud" }
  "mas.chat.tjo.space"     = { to = "any.ingress.tjo.cloud" }
  # MEDIA.TJO.SPACE
  "media.tjo.space"   = { to = "any.ingress.tjo.cloud" }
  "*.media.tjo.space" = { to = "any.ingress.tjo.cloud" }
  # TJO.CLOUD
  "grpc.otel.monitor.tjo.cloud"  = { to = "any.ingress.tjo.cloud" }
  "http.otel.monitor.tjo.cloud"  = { to = "any.ingress.tjo.cloud" }
  "loki.monitor.tjo.cloud"       = { to = "any.ingress.tjo.cloud" }
  "prometheus.monitor.tjo.cloud" = { to = "any.ingress.tjo.cloud" }
  "monitor.tjo.cloud"            = { to = "any.ingress.tjo.cloud" }
  "proxmox.tjo.cloud"            = { to = "any.ingress.tjo.cloud" }
  "vault.tjo.cloud"              = { to = "any.ingress.tjo.cloud" }
  "dashboard.k8s.tjo.cloud"      = { to = "any.ingress.tjo.cloud" }
  "argocd.k8s.tjo.cloud"         = { to = "any.ingress.tjo.cloud" }
  "backup.tjo.cloud"             = { to = "u409586.your-storagebox.de", type = "CNAME" }
}
