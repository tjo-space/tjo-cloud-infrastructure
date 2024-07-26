resource "kubernetes_namespace" "monitoring-system" {
  metadata {
    name = "monitoring-system"
  }
}

resource "kubernetes_manifest" "prometheus-pod-monitors" {
  manifest     = yamldecode(file("${path.module}/manifests/crd-podmonitors.yaml"))
}

resource "kubernetes_manifest" "prometheus-service-monitors" {
  manifest     = yamldecode(file("${path.module}/manifests/crd-servicemonitors.yaml"))
}

resource "helm_release" "grafana-alloy" {
  depends_on      = [kubernetes_manifest.prometheus-pod-monitors, kubernetes_manifest.prometheus-service-monitors]

  name            = "grafana-alloy-deamonset"
  chart           = "alloy"
  repository      = "https://grafana.github.io/helm-charts"
  version         = "0.5.1"
  namespace       = kubernetes_namespace.monitoring-system.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [<<-EOF
    alloy:
      extraEnv:
        - name: "CLUSTER_NAME"
          value: "tjo-cloud"
        - name: "PROMETHEUS_CLIENT_ID"
          value: "o6Tz2215HLvhvZ4RCZCR8oMmCapTu30iwkoMkz6m"
        - name: "LOKI_CLIENT_ID"
          value: "56TYXtgg7QwLjh4lPl1PTu3C4iExOvO1d6b15WuC"
      configMap:
        content: |-
          logging {
            level  = "info"
            format = "logfmt"
          }

          discovery.kubernetes "pods" {
            role = "pod"
            selectors {
              role  = "pod"
              field = "spec.nodeName=" + coalesce(env("HOSTNAME"), constants.hostname)
            }
          }

          // --
          // Metrics
          // --
          prometheus.exporter.unix "self" {}
          discovery.relabel "pod_metrics" {
            targets    = concat(discovery.kubernetes.pods.targets, prometheus.exporter.unix.self.targets)

            // allow override of http scheme with `promehteus.io/scheme`
            rule {
              action = "replace"
              regex = "(https?)"
              source_labels = [
                "__meta_kubernetes_service_annotation_prometheus_io_scheme",
                "__meta_kubernetes_pod_annotation_prometheus_io_scheme",
              ]
              target_label = "__scheme__"
            }

            // allow override of default /metrics path with `prometheus.io/path`
            rule {
              action = "replace"
              regex = "(.+)"
              source_labels = [
                "__meta_kubernetes_service_annotation_prometheus_io_path",
                "__meta_kubernetes_pod_annotation_prometheus_io_path",
              ]
              target_label = "__metrics_path__"
            }

            // allow override of default port with `prometheus.io/port`
            rule {
              action = "replace"
              regex = "([^:]+)(?::\\d+)?;(\\d+)"
              replacement = "$1:$2"
              source_labels = [
                "__address__",
                "__meta_kubernetes_service_annotation_prometheus_io_port",
                "__meta_kubernetes_pod_annotation_prometheus_io_port",
              ]
              target_label = "__address__"
            }

            // Add Namespace
            rule {
              action = "replace"
              source_labels = ["__meta_kubernetes_namespace"]
              target_label = "kubernetes_namespace"
            }
            // Add Pod Name
            rule {
              action = "replace"
              source_labels = ["__meta_kubernetes_pod_name"]
              target_label = "kubernetes_pod"
            }
            // Add Service Name
            rule {
              action = "replace"
              source_labels = ["__meta_kubernetes_service_name"]
              target_label = "kubernetes_service"
            }

            // Add all pod labels
            rule {
              action = "labelmap"
              regex = "__meta_kubernetes_pod_label_(.+)"
            }
            // Add all service labels
            rule {
              action = "labelmap"
              regex = "__meta_kubernetes_service_label_(.+)"
            }
          }
          prometheus.scrape "containers" {
            targets    = discovery.relabel.pod_metrics.output
            forward_to = [prometheus.remote_write.prometheus_monitor_tjo_space.receiver]
          }
          prometheus.remote_write "prometheus_monitor_tjo_space" {
            external_labels = {
              cluster = env("CLUSTER_NAME"),
            }

            endpoint {
              url = "https://prometheus.monitor.tjo.space/api/v1/write"

              oauth2 {
                token_url = "https://id.tjo.space/application/o/token/"
                client_id = env("PROMETHEUS_CLIENT_ID")
                client_secret_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
                endpoint_params = {
                  client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
                }
              }
            }
          }

          // --
          // Logs
          // --
          local.file_match "node_logs" {
            path_targets = [{
                // Monitor syslog to scrape node-logs
                __path__  = "/var/log/syslog",
                job       = "node/syslog",
                node_name = env("HOSTNAME"),
            }]
          }
          loki.source.file "node_logs" {
            targets    = local.file_match.node_logs.targets
            forward_to = [loki.write.loki_monitor_tjo_space.receiver]
          }


          discovery.relabel "pod_logs" {
            targets = discovery.kubernetes.pod.targets

            rule {
              source_labels = ["__meta_kubernetes_namespace"]
              action = "replace"
              target_label = "namespace"
            }
            rule {
              source_labels = ["__meta_kubernetes_pod_name"]
              action = "replace"
              target_label = "pod"
            }
            rule {
              source_labels = ["__meta_kubernetes_pod_container_name"]
              action = "replace"
              target_label = "container"
            }
            rule {
              source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name"]
              action = "replace"
              target_label = "app"
            }
            rule {
              source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_container_name"]
              action = "replace"
              target_label = "job"
              separator = "/"
              replacement = "$1"
            }
            rule {
              source_labels = ["__meta_kubernetes_pod_uid", "__meta_kubernetes_pod_container_name"]
              action = "replace"
              target_label = "__path__"
              separator = "/"
              replacement = "/var/log/pods/*$1/*.log"
            }
            rule {
              source_labels = ["__meta_kubernetes_pod_container_id"]
              action = "replace"
              target_label = "container_runtime"
              regex = "^(\\S+):\\/\\/.+$"
              replacement = "$1"
            }
          }
          loki.source.kubernetes "pod_logs" {
            targets    = discovery.relabel.pod_logs.output
            forward_to = [loki.write.loki_monitor_tjo_space.receiver]
          }
          loki.write "loki_monitor_tjo_space" {
            external_labels = {
              cluster = env("CLUSTER_NAME"),
            }

            endpoint {
              url = "https://loki.monitor.tjo.space/loki/api/v1/push"

              oauth2 {
                token_url = "https://id.tjo.space/application/o/token/"
                client_id = env("LOKI_CLIENT_ID")
                client_secret_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
                endpoint_params = {
                  client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
                }
              }
            }
          }
    EOF
  ]
}
