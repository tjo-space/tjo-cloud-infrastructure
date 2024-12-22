resource "helm_release" "nats" {
  name            = "nats"
  repository      = "https://nats-io.github.io/k8s/helm/charts/"
  chart           = "nats"
  version         = "1.2.8"
  namespace       = kubernetes_namespace.tjo-cloud.metadata[0].name
  atomic          = true
  cleanup_on_fail = true


  values = [<<-EOF
    config:
      cluster:
        enabled: true
        replicas: 2
      jetstream:
        enabled: true
        fileStore:
          pvc:
            size: 10Gi

    podTemplate:
      topologySpreadConstraints:
        kubernetes.io/hostname:
          maxSkew: 1
          whenUnsatisfiable: DoNotSchedule

    service:
      merge:
        spec:
          type: LoadBalancer
    EOF
  ]
}
