# VPC Network
resource "yandex_vpc_network" "main" {
  name        = var.vpc_name
  description = "Main VPC for diplom infrastructure"
}

# Public subnets
resource "yandex_vpc_subnet" "public" {
  for_each       = { for idx, zone in var.zones : zone => idx }
  name           = "public-${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.public_subnet_cidr_prefixes[each.value]]
}

# Private subnets
resource "yandex_vpc_subnet" "private" {
  for_each       = { for idx, zone in var.zones : zone => idx }
  name           = "private-${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.private_subnet_cidr_prefixes[each.value]]
  route_table_id = yandex_vpc_route_table.nat.id
}

# NAT Gateway
resource "yandex_vpc_gateway" "nat" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

# Route table for private subnets
resource "yandex_vpc_route_table" "nat" {
  name       = "nat-route"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}
