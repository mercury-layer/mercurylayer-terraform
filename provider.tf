# Root provider.tf
provider "google" {
  project = var.project_id
  region  = var.default_region
  zone    = var.default_zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.default_region
  zone    = var.default_zone
}

# Example for AWS provider
provider "aws" {
  region = var.aws_region
}

# Example for Scaleway provider
provider "scaleway" {
  organization_id = var.scaleway_organization_id
  region          = var.scaleway_region
}
