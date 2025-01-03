resource "helm_release" "cert-manager" {
  name            = "cert-manager"
  chart           = "cert-manager"
  repository      = "https://charts.jetstack.io"
  version         = "v1.16.2"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true

  values = [<<-EOF
    crds:
      enabled: true

    config:
      apiVersion: controller.config.cert-manager.io/v1alpha1
      kind: ControllerConfiguration
      enableGatewayAPI: true
    EOF
  ]
}

resource "helm_release" "cert-manager-dnsimple" {
  name            = "cert-manager-webhook-dnsimple"
  chart           = "cert-manager-webhook-dnsimple"
  repository      = "https://puzzle.github.io/cert-manager-webhook-dnsimple"
  version         = "v0.1.6"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true

  values = [<<-EOF
      dnsimple:
        token: "not-used"
      certManager:
        namespace: "kube-system"
        serviceAccountName: "cert-manager"
    EOF
  ]
}

resource "helm_release" "envoy" {
  name            = "envoy"
  chart           = "gateway-helm"
  repository      = "oci://docker.io/envoyproxy"
  version         = "v1.2.4"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true
}

resource "helm_release" "metrics-server" {
  name            = "metrics-server"
  chart           = "metrics-server"
  repository      = "https://kubernetes-sigs.github.io/metrics-server/"
  version         = "3.12.2"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true

  values = [<<-EOF
    serviceMonitor:
      enabled: true
    EOF
  ]
}
