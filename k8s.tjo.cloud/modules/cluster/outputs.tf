output "kubeconfig" {
  value = templatefile("${path.module}/kubeconfig.tftpl", {
    cluster : {
      name : var.cluster.name,
      endpoint : local.cluster_endpoint,
      ca : data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate,
    }
    oidc : {
      issuer : var.cluster.oidc.issuer_url,
      id : var.cluster.oidc.client_id,
    }
  })
}

output "name" {
  value = var.cluster.name
}

output "api" {
  value = merge(var.cluster.api, {
    endpoint : local.cluster_endpoint,
    ca : data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate,
  })
}

output "nodes" {
  value = local.nodes_with_address
}
