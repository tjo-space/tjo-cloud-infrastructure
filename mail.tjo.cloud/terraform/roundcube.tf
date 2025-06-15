locals {
  roundcube_version = "9.4.0"
}

resource "random_password" "roundcube" {
  length = 16
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = "mail-tjo-cloud"
  }
}

resource "kubernetes_config_map" "roundcube_config" {
  metadata {
    name      = "roundcube-config"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    "config_system.py" = <<EOF
EOF
  }
}

resource "kubernetes_stateful_set_v1" "roundcube" {
  metadata {
    name      = "roundcube"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "roundcube"
      "app.kubernetes.io/version" = local.roundcube_version
    }
  }

  spec {
    service_name           = "roundcube"
    pod_management_policy  = "Parallel"
    replicas               = 1
    revision_history_limit = 5
    selector {
      match_labels = {
        "app.kubernetes.io/name"    = "roundcube"
        "app.kubernetes.io/version" = local.roundcube_version
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"    = "roundcube"
          "app.kubernetes.io/version" = local.roundcube_version
        }
      }
      spec {
        init_container {
          name              = "init-chmod-data"
          image             = "docker.io/dpage/roundcube4:${local.roundcube_version}"
          image_pull_policy = "IfNotPresent"
          command           = ["/bin/chown", "-R", "5050:5050", "/var/lib/roundcube"]
          volume_mount {
            name       = "roundcube-data"
            mount_path = "/var/lib/roundcube"
            sub_path   = ""
          }
          security_context {
            run_as_user = 0
          }
          resources {
            limits = {
              cpu    = "1000m"
              memory = "250Mi"
            }
          }
        }
        container {
          name              = "roundcube"
          image             = "docker.io/dpage/roundcube4:${local.roundcube_version}"
          image_pull_policy = "IfNotPresent"
          env {
            name  = "roundcube_DEFAULT_EMAIL"
            value = "admin@tjo.cloud"
          }
          env {
            name  = "roundcube_DEFAULT_PASSWORD"
            value = random_password.roundcube.result
          }
          env {
            name  = "roundcube_DISABLE_POSTFIX"
            value = "true"
          }

          port {
            name           = "http"
            container_port = 80
            protocol       = "TCP"
          }

          volume_mount {
            name       = "roundcube-config"
            mount_path = "/etc/roundcube"
            read_only  = true
          }
          volume_mount {
            name       = "roundcube-data"
            mount_path = "/var/lib/roundcube"
            sub_path   = ""
          }

          resources {
            limits = {
              cpu    = "1000m"
              memory = "250Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/misc/ping"
              port = "http"
            }
            initial_delay_seconds = 30
          }
          startup_probe {
            http_get {
              path = "/misc/ping"
              port = "http"
            }
            initial_delay_seconds = 30
          }
          readiness_probe {
            http_get {
              path = "/misc/ping"
              port = "http"
            }
            initial_delay_seconds = 10
          }
        }

        volume {
          name = "roundcube-config"
          config_map {
            name = "roundcube-config"
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "roundcube-data"
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "common"
        resources {
          requests = {
            storage = "3Gi"
          }
        }
      }
    }

    persistent_volume_claim_retention_policy {
      when_deleted = "Delete"
      when_scaled  = "Delete"
    }
  }
}

resource "kubernetes_service" "roundcube" {
  metadata {
    name      = "roundcube"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "roundcube"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name"    = "roundcube"
      "app.kubernetes.io/version" = local.roundcube_version
    }
    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_manifest" "roundcube-http-route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "roundcube"
      namespace = kubernetes_namespace.this.metadata[0].name
    }
    spec = {
      parentRefs = [
        { name = "primary", namespace = "tjo-cloud" }
      ]
      hostnames = [var.domain]
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
              name = "roundcube"
              port = 80
            }
          ]
        }
      ]
    }
  }
}
