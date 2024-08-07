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
  version         = "1.4.6"
  namespace       = kubernetes_namespace.monitoring-system.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [<<-EOF
    cluster:
      name: "${var.cluster_name}"

    prometheus-operator-crds:
      enabled: false
    prometheus-node-exporter:
      enabled: true
    kube-state-metrics:
      enabled: false
    opencost:
      enabled: false

    metrics:
      enabled: true
      serviceMonitors:
        enabled: true
      probes:
        enabled: true
      podMonitors:
        enabled: true
      node-exporter:
        enabled: true
      kubelet:
        enabled: true
      kube-state-metrics:
        enabled: true
      cost:
        enabled: false
      apiserver:
        enabled: true
      autoDiscover:
        enabled: true
      cadvisor:
        enabled: true
      kubeControllerManager:
        enabled: true
      kubeScheduler:
        enabled: true

    logs:
      enabled: true

    profiles:
      enabled: false

    receivers:
      deployGrafanaAgentService: false

    externalServices:
      prometheus:
        host: "https://prometheus.monitor.tjo.cloud"
        writeEndpoint: "/api/v1/write"
        authMode: "oauth2"
        oauth2:
          tokenURL: "https://id.tjo.space/application/o/token/"
          clientId: "o6Tz2215HLvhvZ4RCZCR8oMmCapTu30iwkoMkz6m"
          clientSecretFile: "/var/run/secrets/kubernetes.io/serviceaccount/token"
          endpointParams:
            grant_type: "client_credentials"
            client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
      loki:
        host: "https://loki.monitor.tjo.cloud"
        authMode: "oauth2"
        oauth2:
          tokenURL: "https://id.tjo.space/application/o/token/"
          clientId: "56TYXtgg7QwLjh4lPl1PTu3C4iExOvO1d6b15WuC"
          clientSecretFile: "/var/run/secrets/kubernetes.io/serviceaccount/token"
          endpointParams:
            grant_type: "client_credentials"
            client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
    EOF
  ]
}
