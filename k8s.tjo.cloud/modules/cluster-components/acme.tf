resource "kubernetes_manifest" "acme-gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "acme"
      namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
    }
    spec = {
      gatewayClassName = "envoy"
      listeners = [{
        name     = "http"
        protocol = "HTTP"
        port     = 80
        allowedRoutes = {
          kinds : [{ kind : "HTTPRoute" }]
          namespaces = { from = "All" }
        }
      }],
    }
  }

  wait {
    fields = {
      "status.addresses[0].type" = "IPAddress"
    }
  }
}

resource "kubernetes_manifest" "issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "acme"
    }
    spec = {
      acme = {
        email  = "hostmaster@tjo.cloud"
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "k8s-tjo-cloud-acme-account"
        }
        solvers = [
          {
            http01 = {
              gatewayHTTPRoute = {
                parentRefs = [{
                  name      = kubernetes_manifest.acme-gateway.object.metadata.name
                  namespace = kubernetes_manifest.acme-gateway.object.metadata.namespace
                  kind      = "Gateway"
                }]
              }
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "issuer-ca-tjo-cloud" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "ca-tjo-cloud"
    }
    spec = {
      acme = {
        email  = "hostmaster@tjo.cloud"
        server = "https://ca.cloud.internal/acme/v1/directory"
        caBundle = base64encode(<<EOF
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
        )
        privateKeySecretRef = {
          name = "k8s-tjo-cloud-ca-tjo-cloud-acme-account"
        }
        solvers = [
          {
            http01 = {
              gatewayHTTPRoute = {
                parentRefs = [{
                  name      = kubernetes_manifest.acme-gateway.object.metadata.name
                  namespace = kubernetes_manifest.acme-gateway.object.metadata.namespace
                  kind      = "Gateway"
                }]
              }
            }
          }
        ]
      }
    }
  }
}
