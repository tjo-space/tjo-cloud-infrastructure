locals {
  roundcube_version = "1.6.x-apache"
}

resource "random_password" "roundcube_des_key" {
  length  = 16
  special = false
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

resource "kubernetes_deployment_v1" "roundcube" {
  metadata {
    name      = "roundcube"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "roundcube"
      "app.kubernetes.io/version" = local.roundcube_version
    }
  }

  spec {
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
        container {
          name              = "roundcube"
          image             = "roundcube/roundcubemail:${local.roundcube_version}"
          image_pull_policy = "IfNotPresent"
          env {
            name  = "ROUNDCUEMAIL_DB_TYPE"
            value = "psql"
          }
          env {
            name  = "ROUNDCUEMAIL_DB_HST"
            value = "pink.postgresql.tjo.cloud"
          }
          env {
            name  = "ROUNDCUEMAIL_DB_PORT"
            value = "5432"
          }
          env {
            name  = "ROUNDCUEMAIL_DB_USER"
            value = "mail.tjo.cloud"
          }
          env {
            name  = "ROUNDCUEMAIL_DB_PASSWORD"
            value = var.postgresql_password
          }
          env {
            name  = "ROUNDCUEMAIL_DB_NAME"
            value = "mail.tjo.cloud_roundcube"
          }
          env {
            name  = "ROUNDCUEMAIL_DEFAULT_HOST"
            value = "tls://mail.tjo.cloud"
          }
          env {
            name  = "ROUNDCUEMAIL_SMTP_SERVER"
            value = "tls://mail.tjo.cloud"
          }
          env {
            name  = "ROUNDCUEMAIL_PLUGINS"
            value = "archive,zipdownload,newmail_notifier"
          }
          env {
            name  = "ROUNDCUBEMAIL_DES_KEY"
            value = random_password.roundcube_des_key.result
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

          resources {
            limits = {
              cpu    = "1000m"
              memory = "250Mi"
            }
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
