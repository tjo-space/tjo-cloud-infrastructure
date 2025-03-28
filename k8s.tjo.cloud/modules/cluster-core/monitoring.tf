resource "kubernetes_namespace" "monitoring-system" {
  metadata {
    name = "monitoring-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
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

resource "helm_release" "monitoring" {
  depends_on = [kubernetes_manifest.prometheus-pod-monitors, kubernetes_manifest.prometheus-service-monitors]

  name            = "monitoring"
  chart           = "k8s-monitoring"
  repository      = "https://grafana.github.io/helm-charts"
  version         = "2.0.22"
  namespace       = kubernetes_namespace.monitoring-system.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [<<-EOF
    cluster:
      name: "${var.cluster_name}"

    clusterMetrics:
      enabled: true

    clusterEvents:
      enabled: true

    podLogs:
      enabled: true

    prometheusOperatorObjects:
      enabled: true

    annotationAutodiscovery:
      enabled: true

    alloy-logs:
      enabled: true
    alloy-metrics:
      enabled: true
    alloy-singleton:
      enabled: true

    destinations:
      - name: monitor-tjo-cloud
        type: otlp
        url: "grpc.otel.monitor.tjo.cloud:443"
        auth:
          type: oauth2
          oauth2:
            tokenURL: "https://id.tjo.space/application/o/token/"
            clientId: "Vlw69HXoTJn1xMQaDX71ymGuLVoD9d2WxscGhksh"
            clientSecretFile: "/var/run/secrets/kubernetes.io/serviceaccount/token"
            endpointParams:
              grant_type:
                - "client_credentials"
              client_assertion_type:
                - "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
        logs:
          enabled: true
        metrics:
          enabled: true
        traces:
          enabled: false
    EOF
  ]
}
