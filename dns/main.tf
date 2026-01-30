data "dns_a_record_set" "ingress" {
  host = "any.ingress.tjo.cloud"
}
data "dns_aaaa_record_set" "ingress" {
  host = "any.ingress.tjo.cloud"
}

# List of subdomains that are routed via ingress.
resource "desec_rrset" "ingress" {
  for_each = { for pair in setproduct(["A", "AAAA"], [
    "argocd.k8s",
    "ca",
    "dashboard.k8s",
    "dns",
    "proxmox",
  ]) : "${pair[0]}-${pair[1]}" => { type = pair[0], subname = pair[1] } }

  domain  = "tjo.cloud"
  subname = each.value.subname
  type    = each.value.type
  records = each.value.type == "A" ? data.dns_a_record_set.ingress.addrs : data.dns_aaaa_record_set.ingress.addrs
  ttl     = 3600
}
resource "desec_rrset" "https" {
  for_each = toset([
    "argocd.k8s",
    "ca",
    "dashboard.k8s",
    "dns",
    "proxmox",
  ])

  domain  = "tjo.cloud"
  subname = each.value
  type    = "HTTPS"
  records = ["0 any.ingress.tjo.cloud."]
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
    { type = "TXT", subdomain = "_mta-sts", records = ["v=STSv1; id=12389896138107905122"] },
    { type = "TXT", subdomain = "_dmarc", records = ["v=DMARC1; p=reject; rua=mailto:postmaster@tjo.cloud; ruf=mailto:postmaster@tjo.cloud"] },
    { type = "TXT", subdomain = "_smtp._tls", records = ["v=TLSRPTv1; rua=mailto:postmaster@tjo.cloud"] },
    { type = "TLSA", subdomain = "_25._tcp.mail", records = [
      "3 0 1 d40473bb22eeeec619ffa7972ae7ee1d4e05b2670344c69014377b0b279201c3",
      "3 0 2 423a7893922342406d706fd8a8f6a378f2ca716b0e45c924a2918b557d7e03a015ce507efa9cf588a6a236bbd93cf522cfa26e78867964ca7b36c7241f5528cc",
      "3 1 1 c04cfe7604955bb2c6c57f900c5ca4655af6d1eec5d0a8c4fae4f7256cdfd020",
      "3 1 2 095b866ed351e019a74da79bcd11087a8427f1c91f6548e4ce64bee658997d49ed1a8ae5d4b52115da892546e63a82f4e2a034aeae3d4af6c2b207a1a2048a0e",
      "2 0 1 83624fd338c8d9b023c18a67cb7a9c0519da43d11775b4c6cbdad45c3d997c52",
      "2 0 2 3565cd99fb0bccf03019e4d2276ca5d7c913a3af1ad58a95a8cad181699364f22fb6dc6cc01e071847db3336ae9a122b968d31c5be9a4443e145daba2a1782c6",
      "2 1 1 885bf0572252c6741dc9a52f5044487fef2a93b811cdedfad7624cc283b7cdd5",
      "2 1 2 89d8f1d26d16e94600405c8585e40ad1ecde0023cd447e8b39fd90bc8b482c7bd68d963156e5037023b144ec4caa03af8213296f3a498f69dee691a95a92d722",
    ] },
    ## STORAGE
    { type = "A", subdomain = "synology.storage", records = ["100.79.91.32"] },
    ## BACKUP
    { type = "CNAME", subdomain = "backup", records = ["u409586.your-storagebox.de."] },
    ## NETWORK
    { type = "A", subdomain = "nevaroo.network", records = ["10.0.0.4"] },
    { type = "AAAA", subdomain = "nevaroo.network", records = ["fd74:6a6f::4"] },
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
