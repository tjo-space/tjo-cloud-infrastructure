resource "kubernetes_namespace" "monitoring-system" {
  metadata {
    name = "monitoring-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "kube-state-metrics" {
  depends_on = [kubectl_manifest.crds]

  name            = "kube-state-metrics"
  chart           = "kube-state-metrics"
  repository      = "https://prometheus-community.github.io/helm-charts"
  version         = "7.0.0"
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
  depends_on = [kubectl_manifest.crds]

  name            = "monitoring"
  chart           = "k8s-monitoring"
  repository      = "https://grafana.github.io/helm-charts"
  version         = "3.7.1"
  namespace       = kubernetes_namespace.monitoring-system.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [<<-EOF
    cluster:
      name: "${var.cluster.name}"

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
            tokenURL: "https://id.tjo.cloud/application/o/token/"
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
