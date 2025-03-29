resource "kubernetes_cluster_role_binding" "oidc-admins" {
  metadata {
    name = "id-tjo-space:admins"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "oidc:groups:k8s.tjo.cloud admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
}
