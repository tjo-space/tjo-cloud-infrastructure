module "cluster" {
  source = "../../modules/cluster"

  providers = {
    helm.template = helm.template
  }

  nodes = {
    one = {
      public    = true
      type      = "controlplane"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
    },
    two = {
      public    = true
      type      = "controlplane"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
    },
    three = {
      public    = true
      type      = "controlplane"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
    },
    four = {
      public    = false
      type      = "worker"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
    }
    five = {
      public    = false
      type      = "worker"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
    }
  }

  versions = {
    talos      = "v1.7.5"
    kubernetes = "v1.30.0"
  }

  iso = "proxmox-backup-tjo-cloud:iso/talos-v1.7.5-tailscale-metal-amd64.iso"

  cluster = {
    name   = "pink"
    domain = "k8s.tjo.cloud"
    oidc = {
      client_id  = var.oidc_client_id
      issuer_url = var.oidc_issuer_url
    }
  }

  tailscale_authkey = var.tailscale_authkey
}

resource "local_file" "kubeconfig" {
  content  = module.cluster.kubeconfig
  filename = "${path.module}/kubeconfig"
}

resource "kubernetes_manifest" "hetzner-nodes-as-loadbalancers" {
  manifest = {
    apiVersion = "cilium.io/v2alpha1"
    kind       = "CiliumLoadBalancerIPPool"
    metadata = {
      name = "hetzner-nodes"
    }
    spec = {
      blocks = concat(
        [for k, node in module.cluster.nodes : { start : node.address_ipv4 } if node.public],
        # [for k, node in module.cluster.nodes : { start : node.address_ipv6 } if node.public],
      )
    }
  }
}

resource "kubernetes_namespace" "tjo-cloud" {
  metadata {
    name = "tjo-cloud"
  }
}

resource "kubernetes_secret" "digitalocean-token" {
  metadata {
    name      = "digitalocean-token"
    namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
  }
  data = {
    token = var.digitalocean_token
  }
}

resource "helm_release" "external-dns" {
  name       = "external-dns"
  chart      = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  version    = "v1.14.5"
  namespace  = kubernetes_namespace.tjo-cloud.metadata[0].name

  set {
    name  = "namespaced"
    value = "true"
  }

  set {
    name  = "provider"
    value = "digitalocean"
  }

  set {
    name  = "env[0].name"
    value = "DO_TOKEN"
  }
  set {
    name  = "env[0].valueFrom.secretKeyRef.name"
    value = kubernetes_secret.digitalocean-token.metadata[0].name
  }
  set {
    name  = "env[0].valueFrom.secretKeyRef.key"
    value = "token"
  }

  set_list {
    name  = "sources"
    value = ["gateway-httproute", "gateway-tlsroute", "gateway-tcproute", "gateway-udproute", "ingress", "service"]
  }
}

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.15.1"
  namespace  = kubernetes_namespace.tjo-cloud.metadata[0].name

  set {
    name  = "crds.enabled"
    value = true
  }

  set_list {
    name  = "extraArgs"
    value = ["--enable-gateway-api"]
  }
}


resource "kubernetes_manifest" "tjo-cloud-issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "tjo-cloud"
      namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
    }
    spec = {
      acme = {
        email  = "tine@tjo.space"
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "tjo-cloud-acme-account"
        }
        solvers = [
          {
            dns01 = {
              digitalocean = {
                tokenSecretRef = {
                  name = kubernetes_secret.digitalocean-token.metadata[0].name
                  key  = "token"
                }
              }
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "gateway"
      namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
      annotations = {
        "cert-manager.io/issuer" : "tjo-cloud"
      }
    }
    spec = {
      gatewayClassName = "cilium"
      listeners = [
        {
          name : "http"
          hostname : "*.${module.cluster.name}.${module.cluster.domain}"
          protocol : "HTTPS"
          port : 443
          allowedRoutes : {
            namespaces : {
              from : "Same"
            }
          }
          tls : {
            mode : "Terminate"
            certificateRefs : [
              {
                name : "tjo-cloud-tls"
              }
            ]
          }
        }
      ]
    }
  }
}

resource "helm_release" "dashboard" {
  name       = "kubernetes-dashboard"
  repository = "https://kubernetes.github.io/dashboard"
  chart      = "kubernetes-dashboard"
  version    = "7.5.0"
  namespace  = kubernetes_namespace.tjo-cloud.metadata[0].name
}

resource "kubernetes_manifest" "dashoard-http-route" {
  depends_on = [
    kubernetes_manifest.gateway,
  ]

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "dashboard"
      namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name : "gateway"
        }
      ]
      hostnames = [
        "dashboard.${module.cluster.name}.${module.cluster.domain}"
      ]
      rules = [
        {
          matches = [
            {
              path : {
                value : "/"
                type : "PathPrefix"
              }
            }
          ]
          backendRefs = [
            {
              name : "kubernetes-dashboard-web"
              port : 8000
            }
          ]
        }
      ]
    }
  }
}
