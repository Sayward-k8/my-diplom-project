# Bastion Security Group
resource "yandex_vpc_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Bastion host security group"
  network_id  = var.network_id
  
  ingress {
    protocol       = "TCP"
    description    = "SSH from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
  
  egress {
    protocol       = "ANY"
    description    = "Allow all egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Web Servers Security Group
resource "yandex_vpc_security_group" "web" {
  name        = "web-sg"
  description = "Web servers security group"
  network_id  = var.network_id
  
  ingress {
    protocol       = "TCP"
    description    = "HTTP from load balancer"
    v4_cidr_blocks = [var.vpc_cidr]
    port           = 80
  }
  
  ingress {
    protocol       = "TCP"
    description    = "SSH from bastion"
    v4_cidr_blocks = [var.vpc_cidr]
    port           = 22
  }
  
  ingress {
    protocol       = "TCP"
    description    = "Zabbix agent"
    v4_cidr_blocks = [var.vpc_cidr]
    port           = 10050
  }
  
  egress {
    protocol       = "ANY"
    description    = "Allow all egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Zabbix Security Group
resource "yandex_vpc_security_group" "zabbix" {
  name        = "zabbix-sg"
  description = "Zabbix server security group"
  network_id  = var.network_id
  
  ingress {
    protocol       = "TCP"
    description    = "Zabbix web UI"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }
  
  ingress {
    protocol       = "TCP"
    description    = "Zabbix server"
    v4_cidr_blocks = [var.vpc_cidr]
    port           = 10051
  }
  
  ingress {
    protocol       = "TCP"
    description    = "SSH from bastion"
    v4_cidr_blocks = [var.vpc_cidr]
    port           = 22
  }
  
  egress {
    protocol       = "ANY"
    description    = "Allow all egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Elasticsearch Security Group
resource "yandex_vpc_security_group" "elasticsearch" {
  name        = "elastic-sg"
  description = "Elasticsearch security group"
  network_id  = var.network_id
  
  ingress {
    protocol       = "TCP"
    description    = "Elasticsearch API"
    v4_cidr_blocks = [var.vpc_cidr]
    port           = 9200
  }
  
  ingress {
    protocol       = "TCP"
    description    = "SSH from bastion"
    v4_cidr_blocks = [var.vpc_cidr]
    port           = 22
  }
  
  egress {
    protocol       = "ANY"
    description    = "Allow all egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Kibana Security Group
resource "yandex_vpc_security_group" "kibana" {
  name        = "kibana-sg"
  description = "Kibana security group"
  network_id  = var.network_id
  
  ingress {
    protocol       = "TCP"
    description    = "Kibana web UI"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }
  
  ingress {
    protocol       = "TCP"
    description    = "SSH from bastion"
    v4_cidr_blocks = [var.vpc_cidr]
    port           = 22
  }
  
  egress {
    protocol       = "ANY"
    description    = "Allow all egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group_rule" "elasticsearch_from_web" {
  security_group_binding = yandex_vpc_security_group.elasticsearch.id
  direction              = "ingress"
  description            = "Allow Elasticsearch from web servers"
  protocol               = "TCP"
  port                   = 9200
  v4_cidr_blocks         = ["10.10.0.0/24", "10.11.0.0/24"]
}
