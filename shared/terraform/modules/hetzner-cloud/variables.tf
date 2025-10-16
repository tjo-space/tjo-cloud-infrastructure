variable "name" {
  type = string
}

variable "fqdn" {
  type = string
}

variable "datacenter" {
  type = string
}

variable "image" {
  type    = string
  default = "ubuntu-24.04"
}

variable "server_type" {
  type    = string
  default = "cax11"
}

variable "userdata" {
  type        = any
  default     = {}
  description = "VM Userdata"
}

variable "metadata" {
  type = object({
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
  description = "VM Metadata"
}

variable "username" {
  type        = string
  default     = "bine"
  description = "Linux Username"
}

variable "provision_sh" {
  type        = string
  default     = ""
  description = "Provision Script to be executed."
}

variable "domain" {
  type = string
}

variable "ssh_key_ids" {
  type = list(string)
}
variable "ssh_keys" {
  type = map(string)
}
