resource "helm_release" "envoy" {
  name            = "envoy"
  chart           = "gateway-helm"
  repository      = "oci://docker.io/envoyproxy"
  version         = "v1.2.4"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true
}

resource "kubernetes_manifest" "gateway_class_config" {
  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "EnvoyProxy"
    metadata = {
      name      = "daemonset"
      namespace = "kube-system"
    }
    spec = {
      mergeGateways = true
      provider = {
        type = "Kubernetes"
        kubernetes = {
          envoyService = {
            annotations = {}
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "gateway_class" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "envoy"
    }
    spec = {
      controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
      parametersRef = {
        group     = "gateway.envoyproxy.io"
        kind      = "EnvoyProxy"
        name      = kubernetes_manifest.gateway_class_config.object.metadata.name
        namespace = kubernetes_manifest.gateway_class_config.object.metadata.namespace
      }
    }
  }
}
