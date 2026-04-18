variable "name" {
  description = "Instance name"
  type        = string
}

variable "hostname" {
  description = "Instance hostname"
  type        = string
}

variable "zone" {
  description = "Availability zone"
  type        = string
}

variable "platform_id" {
  description = "Platform ID"
  type        = string
  default     = "standard-v2"
}

variable "resources" {
  description = "Instance resources (cores, memory, core_fraction)"
  type = object({
    cores         = number
    memory        = number
    core_fraction = number
  })
}

variable "disk_image_id" {
  description = "Boot disk image ID"
  type        = string
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 10
}

variable "subnet_id" {
  description = "Subnet ID for network interface"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "nat_enabled" {
  description = "Enable NAT for instance"
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
  sensitive   = true
}

variable "preemptible" {
  description = "Use preemptible instance"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data for cloud-init"
  type        = string
  default     = ""
}

variable "ssh_username" {
  description = "SSH username for the instance"
  type        = string
  default     = "vigonin"
}
