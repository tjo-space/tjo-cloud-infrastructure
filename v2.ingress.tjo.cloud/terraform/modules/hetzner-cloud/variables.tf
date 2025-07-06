variable "nodes" {
  type = map(object({
    name        = string
    fqdn        = string
    datacenter  = string
    image       = optional(string, "ubuntu-24.04")
    server_type = optional(string, "cax11")
    meta = object({
      cloud_provider = string
      service_name   = string
      service_account = object({
        username = string
        password = string
      })
      zerotier = object({
        public_key  = string
        private_key = string
      })
    })
  }))
}

variable "domain" {
  type = string
}

variable "ssh_keys" {
  type = map(string)
}
