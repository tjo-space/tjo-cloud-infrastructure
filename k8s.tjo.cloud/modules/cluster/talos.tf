data "talos_image_factory_extensions_versions" "this" {
  talos_version = var.talos.version
  filters = {
    names = [
      "kata-containers",
      "qemu-guest-agent",
      "wasmedge",
    ]
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info[*].name
        }
      }
    }
  )
}
