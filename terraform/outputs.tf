output "bastion_public_ip" {
  description = "Public IP of bastion host for SSH access"
  value       = module.bastion.external_ip_address
}

output "web_ips" {
  description = "Internal IPs of web servers"
  value       = { for k, vm in module.web : k => vm.internal_ip_address }
}

output "zabbix_public_ip" {
  description = "Public IP of Zabbix server"
  value       = module.zabbix.external_ip_address
}

output "kibana_public_ip" {
  description = "Public IP of Kibana"
  value       = module.kibana.external_ip_address
}

output "load_balancer_ip" {
  description = "Public IP of the load balancer"
  value       = yandex_alb_load_balancer.web.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "web_fqdns" {
  description = "FQDNs of web servers"
  value = {
    for k, vm in module.web : k => "${vm.hostname}.ru-central1.internal"
  }
}

output "zabbix_fqdn" {
  description = "Zabbix server FQDN"
  value = "zabbix.ru-central1.internal"
}

output "elasticsearch_fqdn" {
  description = "Elasticsearch server FQDN"
  value = "elasticsearch.ru-central1.internal"
}

output "kibana_fqdn" {
  description = "Kibana server FQDN"
  value = "kibana.ru-central1.internal"
}
