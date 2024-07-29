resource "kubernetes_namespace" "monitoring-system" {
  metadata {
    name = "monitoring-system"
  }
}

resource "kubernetes_manifest" "prometheus-pod-monitors" {
  manifest = yamldecode(file("${path.module}/manifests/crd-podmonitors.yaml"))
}

resource "kubernetes_manifest" "prometheus-service-monitors" {
  manifest = yamldecode(file("${path.module}/manifests/crd-servicemonitors.yaml"))
}

resource "helm_release" "kube-state-metrics" {
  depends_on = [kubernetes_manifest.prometheus-pod-monitors, kubernetes_manifest.prometheus-service-monitors]

  name            = "kube-state-metrics"
  chart           = "kube-state-metrics"
  repository      = "https://prometheus-community.github.io/helm-charts"
  version         = "5.24.0"
  namespace       = kubernetes_namespace.monitoring-system.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [<<-EOF
    nodeSelector:
      node-role.kubernetes.io/control-plane: ""
    tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        effect: NoSchedule
    updateStrategy: Recreate
    prometheusScrape: false
    prometheus:
      monitor:
        enabled: true
        http:
          honorLabels: true
    EOF
  ]
}

resource "helm_release" "grafana-alloy" {
  depends_on = [kubernetes_manifest.prometheus-pod-monitors, kubernetes_manifest.prometheus-service-monitors]

  name            = "grafana-alloy"
  chart           = "alloy"
  repository      = "https://grafana.github.io/helm-charts"
  version         = "0.5.1"
  namespace       = kubernetes_namespace.monitoring-system.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [<<-EOF
    serviceMonitor:
      enabled: true
    controller:
      type: "deployment"
      nodeSelector:
        node-role.kubernetes.io/control-plane: ""
      tolerations:
        - key: "node-role.kubernetes.io/control-plane"
          effect: "NoSchedule"
    alloy:
      configMap:
        content: |-
          logging {
            level  = "info"
            format = "logfmt"
          }

          // --
          // Discovery
          // --
          discovery.kubernetes "pods" {
            role = "pod"
          }
          discovery.relabel "all" {
            targets = discovery.kubernetes.pods.targets

            // Only process if scrape enabled
            rule {
              source_labels = [
                "__meta_kubernetes_pod_annotation_prometheus_io_scrape",
              ]
              action = "keep"
              regex = "true"
            }
            // allow override of http scheme with `promehteus.io/scheme`
            rule {
              action = "replace"
              regex = "(https?)"
              source_labels = [
                "__meta_kubernetes_pod_annotation_prometheus_io_scheme",
              ]
              target_label = "__scheme__"
            }
            // allow override of default /metrics path with `prometheus.io/path`
            rule {
              action = "replace"
              source_labels = [
                "__meta_kubernetes_pod_annotation_prometheus_io_path",
              ]
              target_label = "__metrics_path__"
            }
            // allow override of default port with `prometheus.io/port`
            // If the metrics port number annotation has a value, override the target address to use it, regardless whether it is
            // one of the declared ports on that Pod.
            rule {
              source_labels = [
                "__meta_kubernetes_pod_annotation_prometheus_io_port",
                "__meta_kubernetes_pod_ip",
              ]
              regex = "(\\d+);(([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4})"
              replacement = "[$2]:$1" // IPv6
              target_label = "__address__"
            }
            rule {
              source_labels = [
                "__meta_kubernetes_pod_annotation_prometheus_io_port",
                "__meta_kubernetes_pod_ip",
              ]
              regex = "(\\d+);((([0-9]+?)(\\.|$)){4})" // IPv4, takes priority over IPv6 when both exists
              replacement = "$2:$1"
              target_label = "__address__"
            }
            rule {
              action = "replace"
              regex = "([^:]+)(?::\\d+)?;(\\d+)"
              replacement = "$1:$2"
              source_labels = [
                "__address__",
                "__meta_kubernetes_pod_annotation_prometheus_io_port",
              ]
              target_label = "__address__"
            }

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
              source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_version"]
              action = "replace"
              target_label = "version"
            }
            rule {
              source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_container_name"]
              action = "replace"
              target_label = "job"
              separator = "/"
              replacement = "$1"
            }
            rule {
              source_labels = ["__meta_kubernetes_pod_container_id"]
              action = "replace"
              target_label = "container_runtime"
              regex = "^(\\S+):\\/\\/.+$"
              replacement = "$1"
            }
          }

          // --
          // Metrics
          // --
          prometheus.scrape "all" {
            honor_labels = true
            targets    = discovery.relabel.all.output
            forward_to = [prometheus.remote_write.prometheus_monitor_tjo_cloud.receiver]
          }
          prometheus.operator.podmonitors "all" {
            forward_to = [prometheus.remote_write.prometheus_monitor_tjo_cloud.receiver]
          }
          prometheus.operator.servicemonitors "all" {
            forward_to = [prometheus.remote_write.prometheus_monitor_tjo_cloud.receiver]
          }
          prometheus.remote_write "prometheus_monitor_tjo_cloud" {
            external_labels = {
              cluster = "${var.cluster_name}",
            }

            endpoint {
              url = "https://prometheus.monitor.tjo.cloud/api/v1/write"

              oauth2 {
                token_url = "https://id.tjo.space/application/o/token/"
                client_id = "o6Tz2215HLvhvZ4RCZCR8oMmCapTu30iwkoMkz6m"
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
          loki.source.kubernetes "pods" {
            targets    = discovery.relabel.all.output
            forward_to = [loki.relabel.all.receiver]
          }
          loki.source.kubernetes_events "all" {
            forward_to = [loki.relabel.all.receiver]
          }
          loki.relabel "all" {
            forward_to = [loki.write.loki_monitor_tjo_cloud.receiver]

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
              source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_version"]
              action = "replace"
              target_label = "version"
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
          loki.write "loki_monitor_tjo_cloud" {
            external_labels = {
              cluster = "${var.cluster_name}",
            }

            endpoint {
              url = "https://loki.monitor.tjo.cloud/loki/api/v1/push"

              oauth2 {
                token_url = "https://id.tjo.space/application/o/token/"
                client_id = "56TYXtgg7QwLjh4lPl1PTu3C4iExOvO1d6b15WuC"
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
