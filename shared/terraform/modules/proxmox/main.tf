data "proxmox_virtual_environment_file" "boot_image" {
  node_name    = var.host
  datastore_id = "local"
  content_type = "iso"
  file_name    = var.boot.image
}

resource "proxmox_virtual_environment_file" "userdata" {
  node_name    = var.host
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data = <<EOF
#cloud-config
${yamlencode(merge(var.userdata, {
    hostname                  = var.name
    fqdn                      = var.fqdn
    prefer_fqdn_over_hostname = true

    users = [
      {
        name                = var.username
        sudo                = "ALL=(ALL) NOPASSWD:ALL"
        ssh_authorized_keys = values(var.ssh_keys)
      }
    ]

    write_files = [
      {
        path     = "/etc/tjo.cloud/meta.json"
        encoding = "base64"
        content  = base64encode(jsonencode(merge(var.metadata, { cloud_region = var.host, cloud_provider = "proxmox" })))
      },
      {
        path     = "/tmp/provision.sh"
        encoding = "base64"
        content  = base64encode(var.provision_sh)
      },
      {
        path    = "/etc/ssh/sshd_config.d/00-cloud-init-port-change.conf"
        content = "Port 2222"
      },
      {
        path = "/etc/firewalld/services/ssh.xml"
        content = trimspace(<<EOF
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>SSH</short>
  <port protocol="tcp" port="2222"/>
</service>
EOF
        )
      }
    ]

    packages = [
      "qemu-guest-agent",
      "ansible-core",
      "firewalld",
    ]
    package_update  = true
    package_upgrade = true

    power_state = {
      mode = "reboot"
    }

    runcmd = concat(
      # If provision script provided, run it.
      # Else we remove the empty file.
      var.provision_sh != "" ? [
        "chmod +x /tmp/provision.sh",
        "/tmp/provision.sh",
        "rm /tmp/provision.sh",
        ] : [
        "rm /tmp/provision.sh",
        ], [
        "shutdown -r +1", # Reboot in one minute
    ], )
})
)}
EOF
file_name = "${var.fqdn}.userconfig.yaml"
}

lifecycle {
  ignore_changes = [source_raw]
}
}

resource "proxmox_virtual_environment_vm" "node" {
  name        = var.fqdn
  node_name   = var.host
  description = var.description

  tags = var.tags

  stop_on_destroy     = true
  timeout_start_vm    = 60
  timeout_stop_vm     = 60
  timeout_shutdown_vm = 60
  timeout_reboot      = 60
  timeout_create      = 240

  cpu {
    cores = var.cores
    type  = "host"
  }
  memory {
    dedicated = var.memory
  }

  boot_order = ["virtio0", "ide3"]

  machine = "q35"
  bios    = "ovmf"
  efi_disk {
    datastore_id = var.boot.storage
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
    timeout = "1m"
  }

  serial_device {}

  tpm_state {
    version      = "v2.0"
    datastore_id = var.boot.storage
  }

  network_device {
    bridge = "vmbr1"
  }

  scsi_hardware = "virtio-scsi-single"

  disk {
    file_id      = data.proxmox_virtual_environment_file.boot_image.id
    interface    = "virtio0"
    datastore_id = var.boot.storage
    size         = var.boot.size
    backup       = false
    cache        = "none"
    iothread     = true
    discard      = "on"
  }

  dynamic "disk" {
    for_each = var.disks
    content {
      interface    = "virtio${disk.value.index != null ? disk.value.index : index(var.disks, disk.value) + 1}"
      datastore_id = disk.value.storage
      size         = disk.value.size
      backup       = true
      cache        = "none"
      iothread     = true
      discard      = "on"
    }
  }

  initialization {
    interface    = "scsi0"
    datastore_id = var.boot.storage

    user_data_file_id = proxmox_virtual_environment_file.userdata.id

    dns {
      servers = ["10.0.0.1", "fd74:6a6f::1"]
    }

    ip_config {
      ipv4 {
        gateway = var.network.ipv4 == "dhcp" ? null : "10.0.0.1"
        address = var.network.ipv4
      }
      ipv6 {
        gateway = var.network.ipv6 == "dhcp" ? null : "fd74:6a6f::1"
        address = var.network.ipv6
      }
    }
  }

  dynamic "hostpci" {
    for_each = var.hostpci
    content {
      device  = hostpci.device
      mapping = hostpci.mapping
      pcie    = hostpci.pcie
      rombar  = hostpci.rombar
      xvga    = hostpci.xvga
    }
  }

  lifecycle {
    ignore_changes = [tpm_state, serial_device]
  }
}
