terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.130"
    }
  }
}

provider "yandex" {
  service_account_key_file = var.service_account_key_file
#  token                    = var.yc_token
  cloud_id                 = var.yc_cloud_id
  folder_id                = var.yc_folder_id
  zone                     = var.default_zone
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  zones                         = var.zones
  vpc_name                      = "diplom-vpc"
  public_subnet_cidr_prefixes   = ["10.0.0.0/24", "10.1.0.0/24"]
  private_subnet_cidr_prefixes  = ["10.10.0.0/24", "10.11.0.0/24"]
}

# Security Groups Module
module "security" {
  source = "./modules/security"
  
  network_id = module.vpc.network_id
  vpc_cidr   = "10.0.0.0/16"
}

# Bastion Instance
module "bastion" {
  source = "./modules/instance"
  
  name              = "bastion"
  hostname          = "bastion"
  zone              = var.zones[0]
  resources         = var.instance_specs
  disk_image_id     = var.image_id
  disk_size         = var.instance_specs.disk_size
  subnet_id         = module.vpc.public_subnets[var.zones[0]].id
  security_group_ids = [module.security.bastion_sg_id]
  nat_enabled       = true
  ssh_public_key    = var.public_ssh_key
  ssh_username      = var.ssh_username
  preemptible       = var.preemptible
}

# Web Instances
module "web" {
  source   = "./modules/instance"
  for_each = toset(var.zones)
  
  name              = "web-${replace(each.key, "-", "")}"
  hostname          = "web-${replace(each.key, "-", "")}"
  zone              = each.key
  resources         = var.instance_specs
  disk_image_id     = var.image_id
  disk_size         = var.instance_specs.disk_size
  subnet_id         = module.vpc.private_subnets[each.key].id
  security_group_ids = [module.security.web_sg_id]
  nat_enabled       = false
  ssh_public_key    = var.public_ssh_key
  ssh_username      = var.ssh_username
  preemptible       = var.preemptible
}

# Zabbix Instance
module "zabbix" {
  source = "./modules/instance"
  
  name              = "zabbix"
  hostname          = "zabbix"
  zone              = var.zones[0]
  resources         = var.instance_specs
  disk_image_id     = var.image_id
  disk_size         = var.instance_specs.disk_size
  subnet_id         = module.vpc.public_subnets[var.zones[0]].id
  security_group_ids = [module.security.zabbix_sg_id]
  nat_enabled       = true
  ssh_public_key    = var.public_ssh_key
  ssh_username      = var.ssh_username
  preemptible       = var.preemptible
}

# Elasticsearch Instance
module "elasticsearch" {
  source = "./modules/instance"
  
  name              = "elasticsearch"
  hostname          = "elasticsearch"
  zone              = var.zones[0]
  resources         = var.instance_specs
  disk_image_id     = var.image_id
  disk_size         = var.instance_specs.disk_size
  subnet_id         = module.vpc.private_subnets[var.zones[0]].id
  security_group_ids = [module.security.elasticsearch_sg_id]
  nat_enabled       = false
  ssh_public_key    = var.public_ssh_key
  ssh_username      = var.ssh_username
  preemptible       = var.preemptible
}

# Kibana Instance
module "kibana" {
  source = "./modules/instance"
  
  name              = "kibana"
  hostname          = "kibana"
  zone              = var.zones[0]
  resources         = var.instance_specs
  disk_image_id     = var.image_id
  disk_size         = var.instance_specs.disk_size
  subnet_id         = module.vpc.public_subnets[var.zones[0]].id
  security_group_ids = [module.security.kibana_sg_id]
  nat_enabled       = true
  ssh_public_key    = var.public_ssh_key
  ssh_username      = var.ssh_username
  preemptible       = var.preemptible
}

# Load Balancer 
resource "yandex_alb_target_group" "web" {
  name = "web-target-group"
  
  dynamic "target" {
    for_each = module.web
    content {
      ip_address   = target.value.internal_ip_address
      subnet_id    = module.vpc.private_subnets[target.key].id
    }
  }
}

resource "yandex_alb_load_balancer" "web" {
  name = "web-load-balancer"
  
  network_id = module.vpc.network_id
  
  allocation_policy {
    location {
      zone_id   = var.default_zone
      subnet_id = module.vpc.public_subnets[var.default_zone].id
    }
  }
  
  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web.id
      }
    }
  }
}


# BACKEND
resource "yandex_alb_backend_group" "web" {
  name = "web-backend-group"
  http_backend {
    name             = "web-backend"
	port             = 80
	weight           = 1
	target_group_ids = [yandex_alb_target_group.web.id]
	
	load_balancing_config {
      panic_threshold = 50
	}
	
    healthcheck {
      timeout             = "1s"
      interval            = "1s"
      healthy_threshold   = 1
      unhealthy_threshold = 2
      
      http_healthcheck {
        path = "/"
      }
    }
  }
}  

resource "yandex_alb_http_router" "web" {
  name = "web-router"
}

resource "yandex_alb_virtual_host" "web" {
  name           = "web-host"
  http_router_id = yandex_alb_http_router.web.id
  
  route {
    name = "default-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web.id
        timeout          = "2s"
      }
    }
  }
}

resource "yandex_compute_snapshot_schedule" "daily_backup" {
  name = "daily-backup-schedule"
  schedule_policy {
    expression = "0 2 * * *"  # каждый день в 2:00 UTC
  }
  snapshot_count = 7          # хранить 7 дней
  disk_ids = [
    module.bastion.disk_id,
    module.web["ru-central1-a"].disk_id,
    module.web["ru-central1-b"].disk_id,
    module.zabbix.disk_id,
    module.elasticsearch.disk_id,
    module.kibana.disk_id
  ]
}
