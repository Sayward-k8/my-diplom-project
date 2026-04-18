output "network_id" {
  description = "ID of the VPC network"
  value       = yandex_vpc_network.main.id
}

output "public_subnets" {
  description = "Map of public subnets by zone"
  value       = yandex_vpc_subnet.public
}

output "private_subnets" {
  description = "Map of private subnets by zone"
  value       = yandex_vpc_subnet.private
}

output "nat_gateway_id" {
  description = "NAT gateway ID"
  value       = yandex_vpc_gateway.nat.id
}
