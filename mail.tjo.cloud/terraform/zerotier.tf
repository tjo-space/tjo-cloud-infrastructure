resource "zerotier_identity" "main" {
  for_each = local.nodes_with_name
}
