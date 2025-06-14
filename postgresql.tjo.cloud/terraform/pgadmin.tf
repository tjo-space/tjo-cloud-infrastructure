locals {
  pgadmin_version = "9.4.0"
}

resource "random_password" "pgadmin" {
  length = 16
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = "postgresql-tjo-cloud"
  }
}

resource "kubernetes_config_map" "pgadmin_config" {
  metadata {
    name      = "pgadmin-config"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    "config_system.py" = <<EOF
MASTER_PASSWORD_REQUIRED = True
MFA_ENABLED = False

AUTHENTICATION_SOURCES = ["oauth2"]
OAUTH2_AUTO_CREATE_USER = True
OAUTH2_CONFIG = [
    {
        "OAUTH2_NAME": "id.tjo.cloud",
        "OAUTH2_DISPLAY_NAME": "id.tjo.cloud",
        "OAUTH2_CLIENT_ID": "${var.pgadmin_client_id}",
        "OAUTH2_CLIENT_SECRET": "${var.pgadmin_client_secret}",
        "OAUTH2_TOKEN_URL": "https://id.tjo.cloud/application/o/token/",
        "OAUTH2_AUTHORIZATION_URL": "https://id.tjo.cloud/application/o/authorize/",
        "OAUTH2_API_BASE_URL": "https://id.tjo.cloud/",
        "OAUTH2_USERINFO_ENDPOINT": "https://id.tjo.cloud/application/o/userinfo/",
        "OAUTH2_SERVER_METADATA_URL": "https://id.tjo.cloud/application/o/postgresqltjocloud/.well-known/openid-configuration",
        "OAUTH2_SCOPE": "openid email profile",
        "OAUTH2_ICON": "",
        "OAUTH2_BUTTON_COLOR": "#7959c9",
    }
]
EOF
  }
}

resource "kubernetes_stateful_set_v1" "pgadmin" {
  metadata {
    name      = "pgadmin"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "pgadmin"
      "app.kubernetes.io/version" = local.pgadmin_version
    }
  }

  spec {
    service_name           = "pgadmin"
    pod_management_policy  = "Parallel"
    replicas               = 1
    revision_history_limit = 5
    selector {
      match_labels = {
        "app.kubernetes.io/name"    = "pgadmin"
        "app.kubernetes.io/version" = local.pgadmin_version
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"    = "pgadmin"
          "app.kubernetes.io/version" = local.pgadmin_version
        }
      }
      spec {
        init_container {
          name              = "init-chmod-data"
          image             = "docker.io/dpage/pgadmin4:${local.pgadmin_version}"
          image_pull_policy = "IfNotPresent"
          command           = ["/bin/chown", "-R", "5050:5050", "/var/lib/pgadmin"]
          volume_mount {
            name       = "pgadmin-data"
            mount_path = "/var/lib/pgadmin"
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
          name              = "pgadmin"
          image             = "docker.io/dpage/pgadmin4:${local.pgadmin_version}"
          image_pull_policy = "IfNotPresent"
          env {
            name  = "PGADMIN_DEFAULT_EMAIL"
            value = "admin@tjo.cloud"
          }
          env {
            name  = "PGADMIN_DEFAULT_PASSWORD"
            value = random_password.pgadmin.result
          }
          env {
            name  = "PGADMIN_DISABLE_POSTFIX"
            value = "true"
          }

          port {
            name           = "http"
            container_port = 80
            protocol       = "TCP"
          }

          volume_mount {
            name       = "pgadmin-config"
            mount_path = "/etc/pgadmin"
            read_only  = true
          }
          volume_mount {
            name       = "pgadmin-data"
            mount_path = "/var/lib/pgadmin"
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
          name = "pgadmin-config"
          config_map {
            name = "pgadmin-config"
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "pgadmin-data"
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

resource "kubernetes_service" "pgadmin" {
  metadata {
    name      = "pgadmin"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "pgadmin"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name"    = "pgadmin"
      "app.kubernetes.io/version" = local.pgadmin_version
    }
    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_manifest" "pgadmin-http-route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "pgadmin"
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
              name = "pgadmin"
              port = 80
            }
          ]
        }
      ]
    }
  }
}
