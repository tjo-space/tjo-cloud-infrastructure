resource "kubernetes_namespace" "tjo-cloud" {
  metadata {
    name = "tjo-cloud"
  }
}

resource "kubernetes_secret" "dnsimple" {
  metadata {
    name      = "dnsimple"
    namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
  }
  data = {
    token      = var.dnsimple.token
    account_id = var.dnsimple.account_id
  }
}

resource "helm_release" "external-dns" {
  name       = "external-dns"
  chart      = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  version    = "v1.15.0"
  namespace  = kubernetes_namespace.tjo-cloud.metadata[0].name

  values = [yamlencode({
    provider : "dnsimple"
    env : [
      {
        name : "DNSIMPLE_OAUTH"
        valueFrom : {
          secretKeyRef : {
            name : kubernetes_secret.dnsimple.metadata[0].name
            key : "token"
          }
        }
      },
      {
        name : "DNSIMPLE_ACCOUNT_ID"
        valueFrom : {
          secretKeyRef : {
            name : kubernetes_secret.dnsimple.metadata[0].name
            key : "account_id"
          }
        }
      },
      {
        name : "DNSIMPLE_ZONES"
        value = join(",", [for domain in var.domains : domain.zone])
      }
    ]
    sources : [
      "ingress",
      "service",
      "gateway-httproute",
      "gateway-grpcroute",
      "gateway-tlsroute",
      "gateway-tcproute"
    ]
    domainFilters : [for domain in var.domains : domain.domain]
  })]
}

resource "helm_release" "cert-manager-dnsimple" {
  name            = "cert-manager-webhook-dnsimple"
  chart           = "cert-manager-webhook-dnsimple"
  repository      = "https://puzzle.github.io/cert-manager-webhook-dnsimple"
  version         = "v0.1.6"
  namespace       = kubernetes_namespace.tjo-cloud.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [<<-EOF
      dnsimple:
        tokenSecretName:  "${kubernetes_secret.dnsimple.metadata[0].name}"
        existingTokenSecret: true
        account_id: "${var.dnsimple.account_id}"
      certManager:
        namespace: "kube-system"
        serviceAccountName: "cert-manager"
    EOF
  ]
}

resource "kubernetes_manifest" "issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "primary"
      namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
    }
    spec = {
      acme = {
        email  = "tine@tjo.space"
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "tjo-cloud-acme-account"
        }
        solvers = [
          {
            dns01 = {
              webhook = {
                solverName = "dnsimple"
                groupName  = "acme.dnsimple.com"
                config = {
                  tokenSecretRef = {
                    name = kubernetes_secret.dnsimple.metadata[0].name
                    key  = "token"
                  }
                  accountID = var.dnsimple.account_id
                }
              }
            }
            selector = {
              dnsZones = [for domain in var.domains : domain.domain]
            }
          },
        ]
      }
    }
  }
}
