locals {
  roundcube_version = "1.6.11-apache"

  postgresql_password = sensitive(provider::dotenv::get_by_key("POSTGRESQL_PASSWORD", "${path.module}/../secrets.env"))
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
            name  = "ROUNDCUBEMAIL_DB_TYPE"
            value = "pgsql"
          }
          env {
            name  = "ROUNDCUBEMAIL_DB_HOST"
            value = "pink.postgresql.tjo.cloud"
          }
          env {
            name  = "ROUNDCUBEMAIL_DB_PORT"
            value = "5432"
          }
          env {
            name  = "ROUNDCUBEMAIL_DB_USER"
            value = "mail.tjo.cloud"
          }
          env {
            name  = "ROUNDCUBEMAIL_DB_PASSWORD"
            value = local.postgresql_password
          }
          env {
            name  = "ROUNDCUBEMAIL_DB_NAME"
            value = "mail.tjo.cloud_roundcube"
          }
          env {
            name  = "ROUNDCUBEMAIL_DEFAULT_HOST"
            value = "ssl://mail.tjo.cloud"
          }
          env {
            name  = "ROUNDCUBEMAIL_DEFAULT_PORT"
            value = "993"
          }
          env {
            name  = "ROUNDCUBEMAIL_SMTP_SERVER"
            value = "ssl://mail.tjo.cloud"
          }
          env {
            name  = "ROUNDCUBEMAIL_SMTP_PORT"
            value = "465"
          }
          env {
            name  = "ROUNDCUBEMAIL_PLUGINS"
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

          resources {
            limits = {
              cpu    = "1000m"
              memory = "512Mi"
            }
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
              name = "roundcube"
              port = 80
            }
          ]
        }
      ]
    }
  }
}
