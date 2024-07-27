resource "helm_release" "cert-manager" {
  name            = "cert-manager"
  chart           = "cert-manager"
  repository      = "https://charts.jetstack.io"
  version         = "v1.15.1"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true

  values = [<<-EOF
    crds:
      enabled: true

    extraArgs:
      - --enable-gateway-api
    EOF
  ]
}

resource "helm_release" "envoy" {
  name            = "envoy"
  chart           = "gateway-helm"
  repository      = "oci://docker.io/envoyproxy"
  version         = "v1.1.0"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true
}

resource "helm_release" "metrics-server" {
  name            = "metrics-server"
  chart           = "metrics-server"
  repository      = "https://kubernetes-sigs.github.io/metrics-server/"
  version         = "3.11.0"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true

  values = [<<-EOF
    serviceMonitor:
      enabled: true
    EOF
  ]
}
