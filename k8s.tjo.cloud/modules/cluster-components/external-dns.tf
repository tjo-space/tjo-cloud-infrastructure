resource "helm_release" "external-dns-privileged" {
  name       = "external-dns-privileged"
  chart      = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  version    = "v1.15.0"
  namespace  = kubernetes_namespace.tjo-cloud.metadata[0].name

  values = [<<-EOF
    provider: dnsimple
    env:
      - name: DNSIMPLE_OAUTH
        valueFrom:
          secretKeyRef:
            name: ${kubernetes_secret.dnsimple.metadata[0].name}
            key: token
      - name: DNSIMPLE_ACCOUNT_ID
        valueFrom:
          secretKeyRef:
            name: ${kubernetes_secret.dnsimple.metadata[0].name}
            key: account_id
      - name: DNSIMPLE_ZONES
        value: "${var.domains.privileged}"
    sources:
      - ingress
      - service
      - gateway-httproute
      - gateway-grpcroute
      - gateway-tlsroute
      - gateway-tcproute
    domainFilters:
      - ${var.domains.privileged}
  EOF
  ]
}

resource "helm_release" "external-dns-user-content" {
  name       = "external-dns-user-content"
  chart      = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  version    = "v1.15.0"
  namespace  = kubernetes_namespace.tjo-cloud.metadata[0].name

  values = [<<-EOF
    provider: dnsimple
    env:
      - name: DNSIMPLE_OAUTH
        valueFrom:
          secretKeyRef:
            name: ${kubernetes_secret.dnsimple.metadata[0].name}
            key: token
      - name: DNSIMPLE_ACCOUNT_ID
        valueFrom:
          secretKeyRef:
            name: ${kubernetes_secret.dnsimple.metadata[0].name}
            key: account_id
      - name: DNSIMPLE_ZONES
        value: "${var.domains.usercontent}"
    sources:
      - ingress
      - service
      - gateway-httproute
      - gateway-grpcroute
      - gateway-tlsroute
      - gateway-tcproute
    domainFilters:
      - ${var.domains.usercontent}
  EOF
  ]
}
