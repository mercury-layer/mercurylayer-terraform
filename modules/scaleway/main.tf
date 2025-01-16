# Required Provider
provider "scaleway" {
  access_key = var.scaleway_access_key
  secret_key = var.scaleway_secret_key
  region     = var.scaleway_region
  zone       = var.scaleway_zone
}

### PROJECT CONFIGURATION ###
data "scaleway_account_project" "project" {}

### INSTANCE CONFIGURATION ###
resource "scaleway_instance_server" "mercurylayer" {
  name        = "mercurylayer-instance"
  type        = var.vm_machine_type
  image       = var.vm_os_image
  enable_ipv6 = true
  tags        = ["http-server"]

  root_volume {
    size_in_gb  = var.vm_disk_size
    volume_type = "l_ssd"
  }

  network_interface {
    ipv4_enabled = true
  }

  dynamic_ip_required = true
  zone                = var.scaleway_zone

  user_data = data.template_file.startup_script_mercurylayer.rendered
}

### NETWORKING ###
resource "scaleway_vpc_private_network" "private_network" {
  name = "ml-vpc1"
}

resource "scaleway_vpc_private_network_subnet" "private_subnetwork" {
  vpc_id     = scaleway_vpc_private_network.private_network.id
  name       = "ml-vpc1-subnet"
  cidr       = var.vpc_subnet_private_ip_reservation
  zone       = var.scaleway_zone
  ip_version = "IPv4"
}

resource "scaleway_vpc_public_gateway" "public_gateway" {
  name   = "public-gateway"
  region = var.scaleway_region
}

resource "scaleway_vpc_public_gateway_dhcp" "dhcp" {
  public_gateway_id = scaleway_vpc_public_gateway.public_gateway.id
  subnet_id         = scaleway_vpc_private_network_subnet.private_subnetwork.id
}

resource "scaleway_vpc_security_group" "firewall" {
  name = "ml-firewall"
}

# Allow HTTP traffic
resource "scaleway_vpc_security_group_rule" "allow_http" {
  security_group_id = scaleway_vpc_security_group.firewall.id
  direction         = "inbound"
  action            = "accept"
  protocol          = "TCP"
  port_range        = "80-80"
  ip_range          = "0.0.0.0/0"
}

# Allow SSH traffic
resource "scaleway_vpc_security_group_rule" "allow_ssh" {
  security_group_id = scaleway_vpc_security_group.firewall.id
  direction         = "inbound"
  action            = "accept"
  protocol          = "TCP"
  port_range        = "22-22"
  ip_range          = "35.235.240.0/20" # Restrict traffic to trusted ranges
}

### DATABASES ###
resource "scaleway_rdb_instance" "primary" {
  name          = "postgresql-primary"
  engine        = "PostgreSQL"
  node_type     = var.postgres_db_tier
  user_name     = var.postgres_db_mercurylayer_user
  password      = random_password.postgres_db_mercurylayer_user_password.result
  version       = var.postgres_db_version
  volume_size   = 20 * 1024 * 1024 * 1024 # 20GB
  is_ha_cluster = true
  region        = var.scaleway_region

  private_network {
    id = scaleway_vpc_private_network.private_network.id
  }

  backup_schedule {
    frequency  = "daily"
    retention  = 14
    start_hour = 5
    timezone   = "UTC"
  }

  tags = ["database"]
}

resource "scaleway_rdb_database" "db_mercury" {
  instance_id = scaleway_rdb_instance.primary.id
  name        = "mercury"
}

resource "scaleway_rdb_database" "db_enclave" {
  instance_id = scaleway_rdb_instance.primary.id
  name        = "enclave"
}

### SECRETS ###
resource "scaleway_kms_secret" "postgres_db_mercurylayer_user_password" {
  name  = "postgres_db_mercurylayer_user_password"
  value = random_password.postgres_db_mercurylayer_user_password.result
}

resource "random_password" "postgres_db_mercurylayer_user_password" {
  length  = 16
  special = false
}

### STARTUP SCRIPT ###
data "template_file" "startup_script_mercurylayer" {
  template = file("${path.module}/${var.vm_mercurylayer_startup_script}")
  vars = {
    project_id   = data.scaleway_account_project.project.id
    default_zone = var.default_zone
  }
}
