resource "kubernetes_cluster_role_binding" "oidc-admins" {
  metadata {
    name = "cloud.tjo.k8s-admin"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "oidc:groups:cloud.tjo.k8s/admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
}

resource "kubernetes_cluster_role_binding" "oidc-read-only" {
  metadata {
    name = "cloud.tjo.k8s-read-only"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "oidc:groups:cloud.tjo.k8s/read-only"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "view"
  }
}
