### RANDOM GENERATOR ###

# Secure password for database users
resource "random_password" "postgres_db_mercurylayer_user_password" {
  length      = 32
  min_lower   = 3
  min_upper   = 3
  min_numeric = 3
  min_special = 3
  special     = true
  override_special = ".+-[]*~_#?"
}
