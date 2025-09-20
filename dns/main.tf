data "dns_a_record_set" "ingress" {
  host = "any.ingress.tjo.cloud"
}
data "dns_aaaa_record_set" "ingress" {
  host = "any.ingress.tjo.cloud"
}

# List of subdomains that are routed via ingress.
resource "desec_rrset" "ingress" {
  for_each = { for pair in setproduct(["A", "AAAA"], [
    "grpc.otel.monitor",
    "http.otel.monitor",
    "loki.monitor",
    "prometheus.monitor",
    "monitor",
    "proxmox",
    "dashboard.k8s",
    "argocd.k8s",
  ]) : "${pair[0]}-${pair[1]}" => { type = pair[0], subname = pair[1] } }

  domain  = "tjo.cloud"
  subname = each.value.subname
  type    = each.value.type
  records = each.value.type == "A" ? data.dns_a_record_set.ingress.addrs : data.dns_aaaa_record_set.ingress.addrs
  ttl     = 3600
}

locals {
  records = [
    ## EMAIL
    { type = "MX", subdomain = "", records = ["10 mail.tjo.cloud."] },
    { type = "TXT", subdomain = "202507e._domainkey", records = ["v=DKIM1; k=ed25519; h=sha256; p=tI29Jb/g3aRaH70XWLOfeleUwudtVHnucgNiNWWp7Zs="] },
    { type = "TXT", subdomain = "202507r._domainkey", records = ["v=DKIM1; k=rsa; h=sha256; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7lHuPkLOYlWtec8cegvMGfBa+e78tGMzC9NxSePHOVQ5hP2Wv0i9QwWwMHa1DVC0JXIFmM5h+it5vjo541/2cCwkZw5WtmlHJH/XnrEO8wvKrfeqnl0kR3WKjCPHuhxXt3iEoEig5o/4+yc03irGZARqsAyR5IDnFvgN+hCw4e5RcA7yIdfl6BEn0n165Q6AoXeSX6bHv3EM/D9UOCgK/08BDMUOl8nESACU4FRgIdNUmw1J5LfY729WkbC2xGFRsqLpp58a9hV7AxUGDO3TbmBcO8L72hwdFh4lC9xKbWsQomlvfrJJ+J3QWCZ4dfIQljwTnZoRPng/6UDvGHmrGQIDAQAB"] },
    { type = "TXT", subdomain = "mail", records = ["v=spf1 a ra=postmaster -all"] },
    { type = "TXT", subdomain = "", records = ["v=spf1 mx ra=postmaster -all"] },
    { type = "SRV", subdomain = "_jmap._tcp", records = ["0 1 443 mail.tjo.cloud."] },
    { type = "SRV", subdomain = "_calddavs._tcp", records = ["0 1 443 mail.tjo.cloud."] },
    { type = "SRV", subdomain = "_carddavs._tcp", records = ["0 1 443 mail.tjo.cloud."] },
    { type = "SRV", subdomain = "_imaps._tcp", records = ["0 1 443 mail.tjo.cloud."] },
    { type = "SRV", subdomain = "_submissions._tcp", records = ["0 1 443 mail.tjo.cloud."] },
    { type = "CNAME", subdomain = "autoconfig", records = ["mail.tjo.cloud."] },
    { type = "CNAME", subdomain = "autodiscover", records = ["mail.tjo.cloud."] },
    { type = "CNAME", subdomain = "mta-sts", records = ["mail.tjo.cloud."] },
    { type = "TXT", subdomain = "_mta-sts", records = ["v=STSv1; id=6866269529996095712"] },
    { type = "TXT", subdomain = "_dmarc", records = ["v=DMARC1; p=reject; rua=mailto:postmaster@tjo.cloud; ruf=mailto:postmaster@tjo.cloud"] },
    { type = "TXT", subdomain = "_smtp._tls", records = ["v=TLSRPTv1; rua=mailto:postmaster@tjo.cloud"] },
    { type = "TLSA", subdomain = "_25._tcp.mail", records = [
      "3 0 1 2d210b2bd7e921e1a7fd11a80b527fe84dff45e186535dc0d1fc35e0b84b67cc",
      "3 0 2 d4db783180cf8ecb5cb6e2d72d6f774e293d92c2ac3e92b7068c17c5148f8a7b6eb06bce0f5b861f19ad526e60d37174b5212ed05bb88566752eba83011d3c88",
      "3 1 1 ec5cd6782de55a70ec41bdcebefcac8ee6febd7777f65931fc5679ade6c2b04b",
      "3 1 2 4f8a71b84006c5f7d4d68793aa4bece277e90515ca44eea3ca665f629e8c8ec29df4d58d1bba5101e4746a1061771843a69c16b0b2155a8614a483e59832a438",
      "2 0 1 aeb1fd7410e83bc96f5da3c6a7c2c1bb836d1fa5cb86e708515890e428a8770b",
      "2 0 2 e18f3d6ccbc578f025c3c7c29ed7bffe1b8eef5b1f839c17298dcf218303d2a63e305f6c1f489691774a18bad836035e5af2de1fc42a3a26cfe9e530f92e3855",
      "2 1 1 cbbc559b44d524d6a132bdac672744da3407f12aae5d5f722c5f6c7913871c75",
      "2 1 2 7d779dd26d37ca5a72fd05f1b815a06078c8e09777697c651fbe012c8d2894e048fcfe24160ee1562602240b6bef44e00f2b7340c84546d6110842bbdeb484a7",
    ] },
    ## STORAGE
    { type = "A", subdomain = "synology.storage", records = ["100.79.91.32"] },
    ## BACKUP
    { type = "CNAME", subdomain = "backup", records = ["u409586.your-storagebox.de."] },
    ## NETWORK
    { type = "A", subdomain = "batuu.network", records = ["100.100.39.38"] },
    { type = "A", subdomain = "endor.network", records = ["100.98.205.27"] },
    { type = "A", subdomain = "jakku.network", records = ["100.78.209.62"] },
    { type = "A", subdomain = "mustafar.network", records = ["100.78.32.102"] },
    { type = "A", subdomain = "nevaroo.network", records = ["100.126.111.13"] },
    { type = "AAAA", subdomain = "batuu.network", records = ["fd7a:115c:a1e0::1101:2728"] },
    { type = "AAAA", subdomain = "endor.network", records = ["fd7a:115c:a1e0::7201:cd22"] },
    { type = "AAAA", subdomain = "jakku.network", records = ["fd7a:115c:a1e0::d601:d13e"] },
    { type = "AAAA", subdomain = "mustafar.network", records = ["fd7a:115c:a1e0::8801:2066"] },
    { type = "AAAA", subdomain = "nevaroo.network", records = ["fd7a:115c:a1e0::1101:6f0d"] },
    ## SYSTEM
    { type = "A", subdomain = "batuu.system", records = ["100.110.88.100"] },
    { type = "A", subdomain = "endor.system", records = ["100.103.129.84"] },
    { type = "A", subdomain = "jakku.system", records = ["100.67.200.27"] },
    { type = "A", subdomain = "mustafar.system", records = ["100.99.13.61"] },
    { type = "A", subdomain = "nevaroo.system", records = ["100.82.48.119"] },
    { type = "AAAA", subdomain = "batuu.system", records = ["fd7a:115c:a1e0::1901:5864"] },
    { type = "AAAA", subdomain = "endor.system", records = ["fd7a:115c:a1e0::3b01:8154"] },
    { type = "AAAA", subdomain = "jakku.system", records = ["fd7a:115c:a1e0::301:c81b"] },
    { type = "AAAA", subdomain = "mustafar.system", records = ["fd7a:115c:a1e0::2601:d3d"] },
    { type = "AAAA", subdomain = "nevaroo.system", records = ["fd7a:115c:a1e0::b301:3077"] },
    { type = "A", subdomain = "any.system", records = [
      "100.110.88.100", "100.103.129.84", "100.67.200.27", "100.99.13.61", "100.82.48.119",
    ] },
    { type = "AAAA", subdomain = "any.system", records = [
      "fd7a:115c:a1e0::1901:5864", "fd7a:115c:a1e0::3b01:8154", "fd7a:115c:a1e0::301:c81b", "fd7a:115c:a1e0::2601:d3d", "fd7a:115c:a1e0::b301:3077",
    ] },
  ]
}
resource "desec_rrset" "records" {
  for_each = { for record in local.records : "${record.type}-${record.subdomain}" => record }

  domain  = "tjo.cloud"
  subname = each.value.subdomain
  type    = each.value.type
  # We must wrap TXT records with quotes (")
  records = each.value.type == "TXT" ? [for record in each.value.records : "\"${record}\""] : each.value.records
  ttl     = 3600
}
