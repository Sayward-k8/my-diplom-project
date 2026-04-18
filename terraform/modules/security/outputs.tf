output "bastion_sg_id" {
  description = "Bastion security group ID"
  value       = yandex_vpc_security_group.bastion.id
}

output "web_sg_id" {
  description = "Web servers security group ID"
  value       = yandex_vpc_security_group.web.id
}

output "zabbix_sg_id" {
  description = "Zabbix security group ID"
  value       = yandex_vpc_security_group.zabbix.id
}

output "elasticsearch_sg_id" {
  description = "Elasticsearch security group ID"
  value       = yandex_vpc_security_group.elasticsearch.id
}

output "kibana_sg_id" {
  description = "Kibana security group ID"
  value       = yandex_vpc_security_group.kibana.id
}
