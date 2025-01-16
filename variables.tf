# Root variables.tf

# Google Cloud variables
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "default_region" {
  description = "The GCP region to use"
  type        = string
  default     = "us-central1"
}

variable "default_zone" {
  description = "The GCP zone to use"
  type        = string
  default     = "us-central1-a"
}

# AWS variables
variable "aws_region" {
  description = "The AWS region to use"
  type        = string
  default     = "us-east-1"
}

# Scaleway variables
variable "scaleway_organization_id" {
  description = "The Scaleway organization ID"
  type        = string
}

variable "scaleway_region" {
  description = "The Scaleway region to use"
  type        = string
  default     = "fr-par"
}
