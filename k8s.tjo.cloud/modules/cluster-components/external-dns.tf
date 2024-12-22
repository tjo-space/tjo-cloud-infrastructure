resource "helm_release" "external-dns-privileged" {
  name       = "external-dns-privileged"
  chart      = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  version    = "v1.15.0"
  namespace  = kubernetes_namespace.tjo-cloud.metadata[0].name

  values = [<<-EOF
    provider: digitalocean
    env:
      - name: DO_TOKEN
        valueFrom:
          secretKeyRef:
            name: ${kubernetes_secret.digitalocean-token.metadata[0].name}
            key: token
    sources:
      - ingress
      - service
      - gateway-httproute
      - gateway-grpcroute
      - gateway-tlsroute
      - gateway-tcproute
    domainFilters:
      - k8s.tjo.cloud
      - internal.k8s.tjo.cloud
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
    provider: digitalocean
    env:
      - name: DO_TOKEN
        valueFrom:
          secretKeyRef:
            name: ${kubernetes_secret.digitalocean-token.metadata[0].name}
            key: token
    sources:
      - ingress
      - service
      - gateway-httproute
      - gateway-grpcroute
      - gateway-tlsroute
      - gateway-tcproute
    domainFilters:
      - user-content.tjo.cloud
  EOF
  ]
}
