locals {
  bulwark_version = "1.19.1"
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = "mail-tjo-cloud"
  }
}

resource "random_password" "session_secret" {
  length  = 32
  special = false
}

resource "random_password" "admin_password" {
  length  = 16
  special = false
}

resource "kubernetes_deployment_v1" "bulwark" {
  metadata {
    name      = "bulwark"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "bulwark"
      "app.kubernetes.io/version" = local.bulwark_version
    }
  }

  spec {
    replicas               = 1
    revision_history_limit = 3
    selector {
      match_labels = {
        "app.kubernetes.io/name"    = "bulwark"
        "app.kubernetes.io/version" = local.bulwark_version
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"    = "bulwark"
          "app.kubernetes.io/version" = local.bulwark_version
        }
      }
      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 1001
          run_as_group    = 1001
          fs_group        = 1001
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }
        container {
          name              = "bulwark"
          image             = "ghcr.io/bulwarkmail/webmail:${local.bulwark_version}"
          image_pull_policy = "IfNotPresent"

          env {
            name  = "HOSTNAME"
            value = "::"
          }
          env {
            name  = "JMAP_SERVER_URL"
            value = "https://mail.tjo.cloud"
          }
          env {
            name  = "SETTINGS_SYNC_ENABLED"
            value = "true"
          }
          env {
            name  = "BULWARK_UPDATE_CHECK"
            value = "off"
          }
          env {
            name  = "TRUSTED_PROXY_DEPTH"
            value = "1"
          }
          env {
            name  = "SESSION_SECRET"
            value = random_password.session_secret.result
          }
          env {
            name  = "ADMIN_PASSWORD"
            value = random_password.admin_password.result
          }
          env {
            name  = "REDIS_URL"
            value = "redis://valkey:6379/0"
          }
          port {
            name           = "http"
            container_port = 3000
            protocol       = "TCP"
          }
          resources {
            requests = {
              cpu = "100m"
            }
            limits = {
              cpu    = "1000m"
              memory = "768Mi"
            }
          }
          startup_probe {
            http_get {
              path = "/api/health"
              port = "http"
            }
            period_seconds    = 2
            failure_threshold = 60
          }
          readiness_probe {
            http_get {
              path = "/api/health"
              port = "http"
            }
            period_seconds    = 30
            failure_threshold = 3
          }
          liveness_probe {
            http_get {
              path = "/api/health"
              port = "http"
            }
            period_seconds    = 30
            failure_threshold = 3
          }

          security_context {
            run_as_non_root            = true
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
          }
          volume_mount {
            name       = "bulwark-data"
            mount_path = "/app/data"
          }
          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }
          volume_mount {
            name       = "next-cache"
            mount_path = "/app/.next/cache"
          }
        }
        volume {
          name = "bulwark-data"
          empty_dir {}
        }
        volume {
          name = "next-cache"
          empty_dir {}
        }
        volume {
          name = "tmp"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_stateful_set_v1" "valkey" {
  metadata {
    name      = "valkey"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "valkey"
    }
  }

  spec {
    service_name           = "valkey"
    replicas               = 1
    revision_history_limit = 3
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "valkey"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "valkey"
        }
      }
      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 999
          run_as_group    = 999
          fs_group        = 999
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }
        container {
          name              = "valkey"
          image             = "valkey/valkey:8"
          image_pull_policy = "IfNotPresent"
          args = [
            "--appendonly",
            "yes",
            "--maxmemory",
            "512mb",
            "--maxmemory-policy",
            "noeviction",
            "--dir",
            "/data",
          ]
          port {
            name           = "redis"
            container_port = 6379
            protocol       = "TCP"
          }
          resources {
            requests = {
              cpu = "50m"
            }
            limits = {
              cpu    = "1000m"
              memory = "640Mi"
            }
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
          }
          volume_mount {
            name       = "valkey-data"
            mount_path = "/data"
          }
          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }
        }
        volume {
          name = "tmp"
          empty_dir {}
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "valkey-data"
      }
      spec {
        storage_class_name = "nevaroo"
        access_modes       = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "1Gi"
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "web-mail-tjo-cloud"
      namespace = kubernetes_namespace.this.metadata[0].name
      annotations = {
        "cert-manager.io/cluster-issuer" = "acme"
      }
    }
    spec = {
      gatewayClassName = "envoy"
      listeners = [
        {
          name     = "web-mail.tjo.cloud"
          hostname = "web-mail.tjo.cloud"
          protocol = "HTTPS"
          port     = 443
          tls = {
            mode = "Terminate"
            certificateRefs = [{
              name = "web-mail.tjo.cloud-tls"
            }]
          }
          allowedRoutes = {
            kinds : [{ kind : "HTTPRoute" }]
            namespaces = { from = "Same" }
          }
        }
      ]
    }
  }

  wait {
    fields = {
      "status.addresses[0].type" = "IPAddress"
    }
  }
}

resource "kubernetes_manifest" "enable-proxy-protocol-policy" {
  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "ClientTrafficPolicy"
    metadata = {
      name      = "enable-proxy-protocol-policy"
      namespace = kubernetes_namespace.this.metadata[0].name
    }
    spec = {
      targetRef = {
        group = "gateway.networking.k8s.io"
        kind  = "Gateway"
        name  = kubernetes_manifest.gateway.object.metadata.name
      }
      enableProxyProtocol = true
    }
  }
}

resource "kubernetes_service" "bulwark" {
  metadata {
    name      = "bulwark"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "bulwark"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name"    = "bulwark"
      "app.kubernetes.io/version" = local.bulwark_version
    }
    port {
      port        = 80
      target_port = "http"
    }
  }
}

resource "kubernetes_manifest" "bulwark-http-route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "bulwark"
      namespace = kubernetes_namespace.this.metadata[0].name
    }
    spec = {
      parentRefs = [
        { name = kubernetes_manifest.gateway.object.metadata.name }
      ]
      hostnames = ["web-${var.domain}"]
      rules = [
        {
          matches = [
            {
              path = {
                value = "/"
                type  = "PathPrefix"
              }
            }
          ]
          backendRefs = [
            {
              name = "bulwark"
              port = 80
            }
          ]
        }
      ]
    }
  }
}
