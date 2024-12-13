# MercuryLayer Infra

The Terraform project for MercuryLayer infra

## 🛠️ Prerequisites

Before running this project, ensure the following are installed and set up:

1. **[gcloud CLI](https://cloud.google.com/sdk/docs/install)**  
   Install and authenticate using your GCP account.
2. **[Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)**  
   Ensure Terraform is installed (version >= `1.8.3`).  

---

## 📋 Setup Instructions

1. Clone this repository to your local machine:

  ```bash
   git clone https://github.com/commerceblock/terraform-mercurylayer.git terraform-mercurylayer
   cd terraform-mercurylayer
   ```

2. Change the default project ID to your project

  ```bash
  variable "project_id" {
    description = "The GCP project ID where all resources will be launched"
    type        = string
    default     = "mercury-441416"
  }
  ```

3. Running the Infra

  ```bash
  terraform init
  terraform plan
  terraform apply
  ```
