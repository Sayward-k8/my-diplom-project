#variable "yc_token" {
#  description = "YC OAuth token"
#  sensitive   = true
#}
variable "service_account_key_file" {
  description = "YC service account"
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "YC ID"
}

variable "yc_folder_id" {
  description = "YC Folder ID"
}

variable "default_zone" {
  description = "Default availability zone"
  default     = "ru-central1-a"
}

variable "zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b"]
}

variable "public_ssh_key" {
  description = "Public SSH key"
  type        = string 
  sensitive   = true
}

variable "ssh_username" {
  description = "SSH username for VMs"
  default     = "vigonin"
}

variable "image_id" {
  description = "Ubuntu 24.04 LTS image ID"
  type        = string
  default     = "fd83ica41cade1mj35sr"
}

variable "preemptible" {
  description = "Use preemptible VMs"
  type        = bool
  default     = true
}

variable "instance_specs" {
  description = "Instance specifications"
  type = object({
    platform_id   = string
    cores         = number
    memory        = number
    core_fraction = number
    disk_size     = number
  })
  default = {
    platform_id   = "standard-v2"
    cores         = 2
    memory        = 2
    core_fraction = 20
    disk_size     = 10
  }
}
