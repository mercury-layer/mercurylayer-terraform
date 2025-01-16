# This code is compatible with Terraform 4.25.0 and versions that are backwards compatible to 4.25.0.
# For information about validating this Terraform code, see https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build#format-and-validate-the-configuration
resource "google_project_service" "before_required_apis" {
  project            = var.project_id
  service            = "serviceusage.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "required_apis" {
  project = var.project_id
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "iap.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false

  depends_on = [google_project_service.before_required_apis]
}

### PROJECT CONFIGURATION ###
data "google_project" "project" {

  depends_on = [google_project_service.required_apis]
}

### SERVICE ACCOUNTS ###

# Create a custom service accounts for each VM
resource "google_service_account" "service_account_vm_mercurylayer" {
  account_id = "sa-vm-mercurylayer"

  depends_on = [google_project_service.required_apis]
}

### IAM ###

# Add roles to the VMs service accounts to read secrets from Secret Manager
resource "google_project_iam_binding" "gce_role_secret_manager" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  members = [
    google_service_account.service_account_vm_mercurylayer.member,
  ]

  depends_on = [google_service_account.service_account_vm_mercurylayer]
}

### SECRET MANAGER ###

# Postgres DB user mercurylayer login password
resource "google_secret_manager_secret" "postgres_db_mercurylayer_user_password" {
  secret_id = "postgres_db_mercurylayer_user_password"
  replication {
    auto {}
  }

  depends_on = [google_project_service.required_apis]
}
resource "google_secret_manager_secret_version" "postgres_db_mercurylayer_user_password" {
  secret      = google_secret_manager_secret.postgres_db_mercurylayer_user_password.id
  secret_data = random_password.postgres_db_mercurylayer_user_password.result
}

# Create mercury database in the primary Postgres Cloud SQL instance
resource "google_sql_database" "db_mercury" {
  name     = "mercury"
  instance = google_sql_database_instance.primary.name
}

resource "google_sql_database" "db_enclave" {
  name     = "enclave"
  instance = google_sql_database_instance.primary.name
}


### NETWORKING ###

# Create custom VPC
resource "google_compute_network" "private_network" {
  name                            = "ml-vpc1"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true

  depends_on = [google_project_service.required_apis]
}

# Create subnet
resource "google_compute_subnetwork" "private_subnetwork" {
  name                     = "ml-vpc1-subnet-${var.default_region}"
  ip_cidr_range            = var.vpc_subnet_private_ip_reservation
  region                   = var.default_region
  network                  = google_compute_network.private_network.id
  private_ip_google_access = true
}

# Create default route to Internet
resource "google_compute_route" "private_network_default_to_internet" {
  name             = "default-to-internet"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.private_network.name
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}

# Reserve private IP addresses for internal VPC peering with Google Services
resource "google_compute_global_address" "private_ip_reservation" {
  provider      = google-beta
  name          = "private-ip-reservation-google-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = var.vpc_subnet_google_services_ip_reservation
  prefix_length = var.vpc_subnet_google_services_ip_reservation_length
  network       = google_compute_network.private_network.id

  depends_on = [google_project_service.required_apis]
}

# Reserve static external IP for VLS VM
resource "google_compute_address" "ml-external-ip" {
  name = "ml-external-static-ipv4-address"

  depends_on = [google_project_service.required_apis]
}

# Create VPC connection with Google Services using the allocated reservation
resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_reservation.name]
}

# Create firewall rule to allow port 80 to be open to public
resource "google_compute_firewall" "allow-http" {
  name    = "allow-http"
  network = google_compute_network.private_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["allow-http"]
}

# Create firewall rule to allow traffic from IAP to SSH (tcp/22)
resource "google_compute_firewall" "port_22" {
  name        = "allow-tcp-22-from-iap"
  description = "Allows traffic only from Google IAP proxy. More info visit: https://cloud.google.com/iap/docs/using-tcp-forwarding#tunneling_ssh_connections"
  network     = google_compute_network.private_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
}

### DATABASES ###

# Create Postgres Cloud SQL instance with private IP
resource "google_sql_database_instance" "primary" {
  name                = "postgresql-primary"
  region              = var.default_region
  database_version    = var.postgres_db_version
  deletion_protection = var.postgres_db_deletion_protection

  settings {
    tier                        = var.postgres_db_tier
    disk_size                   = 20
    disk_type                   = "PD_SSD"
    disk_autoresize             = true
    deletion_protection_enabled = var.postgres_db_deletion_protection

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.private_network.id
      enable_private_path_for_google_cloud_services = true
    }

    # Added to provide HA and backups
    edition           = "ENTERPRISE"
    availability_type = "REGIONAL"
    backup_configuration {
      enabled                        = true
      start_time                     = "05:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = 14 # Has to be bigger than transaction_log_retention_days
        retention_unit   = "COUNT"
      }
    }

    # Configure the maintenance window (cannot be disabled)
    maintenance_window {
      day          = 7
      hour         = 5
      update_track = "week5"
    }

    location_preference {
      zone = var.default_zone
    }

    # Added to enable Query Insights
    insights_config {
      query_insights_enabled = true
    }
  }

  depends_on = [google_project_service.required_apis, google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_user" "user_mercurylayer" {
  instance = google_sql_database_instance.primary.name
  name     = var.postgres_db_mercurylayer_user
  password = google_secret_manager_secret_version.postgres_db_mercurylayer_user_password.secret_data

  depends_on = [google_secret_manager_secret_version.postgres_db_mercurylayer_user_password]
}

# VM Instance
resource "google_compute_instance" "mercurylayer" {
  project = var.project_id

  boot_disk {
    auto_delete = true
    device_name = "mercurylayer"

    initialize_params {
      image = var.vm_os_version
      size  = 20
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  machine_type     = var.vm_mercurylayer_machine_type
  min_cpu_platform = "AMD Milan"
  name             = "mercurylayer"

  network_interface {
    network    = google_compute_network.private_network.name
    subnetwork = google_compute_subnetwork.private_subnetwork.name
    access_config {
      network_tier = "PREMIUM"
      nat_ip       = google_compute_address.ml-external-ip.address
    }

    nic_type   = "GVNIC"
    stack_type = "IPV4_ONLY"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }
  
  service_account {
    email  = google_service_account.service_account_vm_mercurylayer.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  confidential_instance_config {
    enable_confidential_compute = true
    confidential_instance_type  = "SEV"
  }

  tags = ["http-server"]
  zone = var.default_zone

  metadata_startup_script = data.template_file.startup-script-mercurylayer.rendered
}

# Startup scripts
data "template_file" "startup-script-mercurylayer" {
  template = file("${path.module}/${var.vm_mercurylayer_startup_script}")
  vars = {
    project_id           = var.project_id
    default_zone         = var.default_zone
  }
}
