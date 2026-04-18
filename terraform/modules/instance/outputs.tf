output "instance_id" {
  description = "Instance ID"
  value       = yandex_compute_instance.this.id
}

output "hostname" {
  description = "Instance hostname"
  value       = yandex_compute_instance.this.hostname
}

output "internal_ip_address" {
  description = "Internal IP address"
  value       = yandex_compute_instance.this.network_interface[0].ip_address
}

output "external_ip_address" {
  description = "External IP address (if NAT enabled)"
  value       = var.nat_enabled ? yandex_compute_instance.this.network_interface[0].nat_ip_address : null
}

output "disk_id" {
  description = "Boot disk ID for backup schedules"
  value       = yandex_compute_instance.this.boot_disk[0].disk_id
}
