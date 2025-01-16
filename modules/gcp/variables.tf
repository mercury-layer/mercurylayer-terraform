variable "GOOGLE_CREDENTIALS" {
  description = "Google Service Account for auth to GCP"
  type        = string
  sensitive   = true
  default     = ""
}

variable "default_region" {
  description = "Defaut region for resources"
  type        = string
  default     = "us-central1"
}

variable "default_zone" {
  description = "Defaut zone for zonal resources (has to be a zone in the same region as default_region)"
  type        = string
  default     = "us-central1-a"
}

variable "project_id" {
  description = "The GCP project ID where all resources will be launched"
  type        = string
  default     = "mercury-441416"
}

variable "postgres_db_version" {
  description = "Postgres Cloud SQL DB engine version"
  type        = string
  default     = "POSTGRES_15"
}

variable "postgres_db_tier" {
  description = "Postgres Cloud SQL DB engine size/tier (CPU & Memory)"
  type        = string
  default     = "db-f1-micro"
}

variable "postgres_db_deletion_protection" {
  description = "Postgres Cloud SQL deletion protection enabled?"
  type        = bool
  default     = true
}

variable "postgres_db_mercurylayer_user" {
  description = "The mercurylayer username for the Postgres Cloud SQL instance"
  type        = string
  default     = "mercurylayer"
}

variable "vpc_subnet_google_services_ip_reservation" {
  description = "IP base for range reserved for Google Services"
  type        = string
  default     = "10.100.0.0"
}

variable "vpc_subnet_google_services_ip_reservation_length" {
  description = "IP segment size reserved (CIDR) for Google Services"
  type        = number
  default     = 24
}

variable "vpc_subnet_private_ip_reservation" {
  description = "IP segment reserved for private VPC (CIDR)"
  type        = string
  default     = "10.1.0.0/24"
}

variable "security_ssh_enable_2fa" {
  description = "Define if 2FA is forced in Compute Engine"
  type        = string
  default     = "TRUE"
}

variable "security_ssh_enable_oslogin" {
  description = "Define if OS login is enabled in Compute Engine"
  type        = string
  default     = "TRUE"
}

variable "vm_os_version" {
  description = "Define the family of the OS to run"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "vm_mercurylayer_machine_type" {
  description = "Size and family of the VM"
  type        = string
  default     = "n2d-standard-2"
}

variable "vm_mercurylayer_startup_script" {
  description = "Startup script to be run when the VM starts"
  type        = string
  default     = "../scripts/startup-script/startup-script-mercurylayer.tpl"
}
