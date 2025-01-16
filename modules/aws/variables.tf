# General Configuration
variable "project_id" {
  description = "The project ID for the AWS deployment (for tagging and identification purposes)."
  type        = string
}

variable "default_region" {
  description = "The default AWS region for resource creation."
  type        = string
  default     = "us-east-1"
}

variable "default_zone" {
  description = "The default availability zone for the AWS deployment."
  type        = string
}

# Networking Variables
variable "vpc_subnet_private_ip_reservation" {
  description = "The CIDR block for the VPC subnet."
  type        = string
  default     = "10.0.0.0/16"
}

variable "firewall_ssh_source_ips" {
  description = "Allowed source IP ranges for SSH access."
  type        = list(string)
  default     = ["0.0.0.0/0"] # Update to restrict access
}

# EC2 Instance Variables
variable "vm_instance_type" {
  description = "The instance type for the EC2 instance (e.g., t3.medium)."
  type        = string
  default     = "t3.medium"
}

variable "vm_os_version" {
  description = "The Amazon Machine Image (AMI) ID for the EC2 instance."
  type        = string
  default     = "ami-0c94855ba95c71c99" # Amazon Linux 2 AMI (Update as necessary)
}

variable "vm_mercurylayer_startup_script" {
  description = "The path to the startup script for the EC2 instance."
  type        = string
  default     = "../scripts/startup-script-mercurylayer.tpl"
}

variable "key_name" {
  description = "The name of the SSH key pair to access the EC2 instance."
  type        = string
  default     = ""
}

# RDS (PostgreSQL) Variables
variable "postgres_db_engine" {
  description = "The version of PostgreSQL to use for the RDS instance."
  type        = string
  default     = "13.7"
}

variable "postgres_db_instance_type" {
  description = "The instance class for the RDS database (e.g., db.t3.medium)."
  type        = string
  default     = "db.t3.medium"
}

variable "postgres_db_tier" {
  description = "The performance tier for the RDS instance."
  type        = string
  default     = "db.t3.medium"
}

variable "postgres_db_deletion_protection" {
  description = "Enable deletion protection for the RDS instance."
  type        = bool
  default     = false
}

variable "postgres_db_mercurylayer_user" {
  description = "The username for the PostgreSQL database."
  type        = string
  default     = "mercurylayer"
}
