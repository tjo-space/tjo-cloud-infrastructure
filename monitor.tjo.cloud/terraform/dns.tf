resource "desec_rrset" "web" {
  for_each = toset([
    "",
    "prometheus.",
    "loki.",
    "grpc.otel.",
    "http.otel.",
  ])

  domain  = "tjo.cloud"
  subname = "${each.key}new.${trimsuffix(var.domain, ".tjo.cloud")}"
  type    = "CNAME"
  records = ["any.ingress.tjo.cloud."]
  ttl     = 3600
}

resource "desec_rrset" "node_a" {
  for_each = local.nodes_deployed
  domain   = "tjo.cloud"
  subname  = "${each.value.name}.${trimsuffix(var.domain, ".tjo.cloud")}"
  type     = "A"
  records  = [each.value.private_ipv4]
  ttl      = 3600
}
resource "desec_rrset" "node_aaaa" {
  for_each = local.nodes_deployed
  domain   = "tjo.cloud"
  subname  = "${each.value.name}.${trimsuffix(var.domain, ".tjo.cloud")}"
  type     = "AAAA"
  records  = [each.value.private_ipv6]
  ttl      = 3600
}
