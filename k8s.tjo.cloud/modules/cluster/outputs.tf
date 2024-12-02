output "name" {
  value = var.cluster.name
}

output "api" {
  value = merge(var.cluster.api, {
    internal : merge(var.cluster.api.internal, {
      endpoint : local.cluster_internal_endpoint,
    }),
    public : merge(var.cluster.api.public, {
      endpoint : local.cluster_public_endpoint,
    }),
    ca : talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate,
  })
}

output "nodes" {
  value = local.nodes_with_address
}
