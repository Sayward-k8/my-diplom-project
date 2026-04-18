locals {
  user_data_config = <<-EOF
#cloud-config
users:
  - name: ${var.ssh_username}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${var.ssh_public_key}
  - name: vigonin
    disable: true
    lock_passwd: true
packages:
  - htop
  - git
  - curl
  - wget
package_update: true
package_upgrade: false
runcmd:
  - echo "user-data completed at $(date)" > /var/log/user-data-complete.log
EOF
}

resource "yandex_compute_instance" "this" {
  name        = var.name
  hostname    = var.hostname
  platform_id = var.platform_id
  zone        = var.zone
  
  resources {
    cores         = var.resources.cores
    memory        = var.resources.memory
    core_fraction = var.resources.core_fraction
  }
  
  boot_disk {
    initialize_params {
      image_id = var.disk_image_id
      size     = var.disk_size
    }
  }
  
  network_interface {
    subnet_id          = var.subnet_id
    security_group_ids = var.security_group_ids
    nat                = var.nat_enabled
  }
    
  metadata = {
    user-data = local.user_data_config
  }
  
  scheduling_policy {
    preemptible = var.preemptible
  }
}
