variable "vpc_name" {
  description = "VPC network name"
  type        = string
  default     = "diplom-vpc"
}

variable "zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "public_subnet_cidr_prefixes" {
  description = "CIDR prefixes for public subnets"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.1.0.0/24"]
}

variable "private_subnet_cidr_prefixes" {
  description = "CIDR prefixes for private subnets"
  type        = list(string)
  default     = ["10.10.0.0/24", "10.11.0.0/24"]
}
