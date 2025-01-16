variable "SCALEWAY_ACCESS_KEY" {
  description = "Scaleway Access Key for authentication"
  type        = string
  sensitive   = true
}

variable "SCALEWAY_SECRET_KEY" {
  description = "Scaleway Secret Key for authentication"
  type        = string
  sensitive   = true
}

variable "default_region" {
  description = "Default region for resources"
  type        = string
  default     = "fr-par"
}

variable "default_zone" {
  description = "Default zone for zonal resources (has to be a zone in the same region as default_region)"
  type        = string
  default     = "fr-par-1"
}

variable "project_id" {
  description = "The Scaleway project ID where all resources will be launched"
  type        = string
  default     = "mercurylayer-project"
}

variable "postgres_db_engine" {
  description = "PostgreSQL database engine version"
  type        = string
  default     = "14"
}

variable "postgres_db_instance_type" {
  description = "Postgres database instance type"
  type        = string
  default     = "DB-DEV-S"
}

variable "postgres_db_deletion_protection" {
  description = "Enable deletion protection for the PostgreSQL database"
  type        = bool
  default     = true
}

variable "postgres_db_mercurylayer_user" {
  description = "The username for the PostgreSQL database"
  type        = string
  default     = "mercurylayer"
}

variable "vpc_subnet_private_ip_reservation" {
  description = "IP range reserved for private VPC (CIDR)"
  type        = string
  default     = "10.1.0.0/24"
}

variable "vm_os_version" {
  description = "Define the OS image for the instance"
  type        = string
  default     = "ubuntu-focal"
}

variable "vm_instance_type" {
  description = "Define the size and type of the instance"
  type        = string
  default     = "DEV1-M"
}

variable "firewall_allow_http" {
  description = "Allow HTTP access to instances (true/false)"
  type        = bool
  default     = true
}

variable "firewall_allow_ssh" {
  description = "Allow SSH access to instances (true/false)"
  type        = bool
  default     = true
}

variable "firewall_ssh_source_ips" {
  description = "Allowed source IPs for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "firewall_http_source_ips" {
  description = "Allowed source IPs for HTTP access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "postgres_db_password" {
  description = "Password for the PostgreSQL database user"
  type        = string
  sensitive   = true
}

variable "public_gateway_enabled" {
  description = "Enable public gateway for the private network"
  type        = bool
  default     = true
}

variable "vm_mercurylayer_startup_script" {
  description = "Startup script to be run when the VM starts"
  type        = string
  default     = "../scripts/startup-script/startup-script-mercurylayer.tpl"
}
