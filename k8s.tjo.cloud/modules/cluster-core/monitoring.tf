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
  version         = "7.5.1"
  namespace       = kubernetes_namespace.monitoring-system.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    nodeSelector = {
      "node-role.kubernetes.io/control-plane" = ""
    }
    tolerations = [
      {
        key    = "node-role.kubernetes.io/control-plane"
        effect = "NoSchedule"
      }
    ]

    priorityClassName = "system-cluster-critical"

    updateStrategy   = "Recreate"
    prometheusScrape = false
    prometheus = {
      monitor = {
        enabled = true
        http = {
          honorLabels = true
        }
      }
    }
  })]
}

resource "helm_release" "monitoring" {
  depends_on = [kubectl_manifest.crds]

  name            = "monitoring"
  chart           = "k8s-monitoring"
  repository      = "https://grafana.github.io/helm-charts"
  version         = "4.2.0"
  namespace       = kubernetes_namespace.monitoring-system.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    cluster = {
      name = var.cluster.name
    }

    collectors = {
      metrics-collector = {
        presets = ["clustered", "statefulset"]
        controller = {
          priorityClassName = "system-cluster-critical"
          tolerations = [{
            key    = "node-role.kubernetes.io/control-plane"
            effect = "NoSchedule"
          }]
        }
      }
      logs-collector = {
        presets = ["filesystem-log-reader", "daemonset"]
        controller = {
          priorityClassName = "system-node-critical"
        }
      }
      events-collector = {
        presets = ["singleton"]
        controller = {
          priorityClassName = "system-cluster-critical"
          tolerations = [{
            key    = "node-role.kubernetes.io/control-plane"
            effect = "NoSchedule"
          }]
        }
      }
    }

    # Features
    clusterMetrics = {
      enabled   = true
      collector = "metrics-collector"
      controlPlane = {
        enabled = true
      }
      kube-state-metrics = {
        enabled   = true
        namespace = kubernetes_namespace.monitoring-system.metadata[0].name
        labelMatchers = {
          "app.kubernetes.io/name" = "kube-state-metrics"
        }
      }
    }
    hostMetrics = {
      enabled   = true
      collector = "metrics-collector"
      linuxHosts = {
        enabled = true
        metricsTuning = {
          useDefaultAllowList     = true
          useIntegrationAllowList = true
        }
      }
      nodeLabels = {
        availabilityZone = true
        instanceType     = true
        nodeArchitecture = true
        nodeOS           = true
        nodePool         = true
        nodeRole         = true
        region           = true
      }
    }
    clusterEvents = {
      enabled   = true
      collector = "events-collector"
    }
    podLogsViaLoki = {
      enabled   = true
      collector = "logs-collector"
      annotations = {
        app     = "app.kubernetes.io/name"
        version = "app.kubernetes.io/version"
      }
    }
    prometheusOperatorObjects = {
      enabled   = true
      collector = "metrics-collector"
    }
    annotationAutodiscovery = {
      enabled   = true
      collector = "metrics-collector"
    }

    telemetryServices = {
      node-exporter = {
        deploy            = true
        priorityClassName = "system-cluster-critical"
      }
    }

    destinations = {
      monitor-tjo-cloud = {
        type = "otlp"
        url  = "grpc.otel.monitor.cloud.internal:443"
        auth = {
          type = "oauth2"
          oauth2 = {
            tokenURL         = "https://id.tjo.cloud/application/o/token/"
            clientId         = "Vlw69HXoTJn1xMQaDX71ymGuLVoD9d2WxscGhksh"
            clientSecretFile = "/var/run/secrets/kubernetes.io/serviceaccount/token"
            endpointParams = {
              grant_type            = ["client_credentials"]
              client_assertion_type = ["urn:ietf:params:oauth:client-assertion-type:jwt-bearer"]
            }
          }
        }
        tls = {
          ca = <<EOF
-----BEGIN CERTIFICATE-----
MIIBfzCCASSgAwIBAgIQTwBj3msM0GPYkUSHuEsKEjAKBggqhkjOPQQDAjAeMRww
GgYDVQQDExNjYS50am8uY2xvdWQgLSBSb290MCAXDTI2MDIwNjIwNTc0MFoYDzIw
NTEwMzE0MTI1NzQwWjAeMRwwGgYDVQQDExNjYS50am8uY2xvdWQgLSBSb290MFkw
EwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAENghQfaCunCDzn0BmU8vI5X79OAqZ7Uob
8tM38BJmvUmafJMyxpvlIKNgotXJfnTw1GN5mR6u4eqvSRclhUcRtKNCMEAwDgYD
VR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFD0gfxAPGvuX
jmqfZ1CreFQT+WuQMAoGCCqGSM49BAMCA0kAMEYCIQCY0suGAsNGx7n2+F+Z786Q
dubTJY1VA3fqwc0ZpO+AtQIhAOmeM2O7iFarM2KILzS5189DsdNIn5pp9v5uLOSX
T8+p
-----END CERTIFICATE-----
EOF
        }
        logs = {
          enabled = true
        }
        metrics = {
          enabled = true
        }
        traces = {
          enabled = false
        }
      }
    }

    alloy-operator = {
      priorityClassName = "system-cluster-critical"
      affinity = {
        nodeAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = {
            nodeSelectorTerms = [{
              matchExpressions = [{
                key      = "node-role.kubernetes.io/control-plane"
                operator = "Exists"
              }]
            }]
          }
        }
      }
      tolerations = [{
        key    = "node-role.kubernetes.io/control-plane"
        effect = "NoSchedule"
      }]
    }
  })]
}
