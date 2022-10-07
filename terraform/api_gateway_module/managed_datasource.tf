# create the kong db
resource "google_sql_database" "kong" {
  name     = "kong"
  instance = google_sql_database_instance.datasource_instance.name
}

# create the konga db
resource "google_sql_database" "konga" {
  name     = "konga"
  instance = google_sql_database_instance.datasource_instance.name
}

resource "google_sql_database_instance" "datasource_instance" {
  name             = "api-gateway-${var.env}"
  database_version = "POSTGRES_9_6"
  settings {
    tier              = "db-custom-4-4096" # 2 CPU, 4GB (=2*1024=2048MiB) ram -> db-custom-2-2048
    availability_type = "REGIONAL"
    disk_size         = 10 # 10 GB is the smallest disk size    
    ip_configuration {
      ipv4_enabled    = false
      private_network = "projects/xxx/global/networks/vpc"
    }
  }
}

resource "google_sql_user" "db_user" {
  name     = var.datasource_username
  instance = google_sql_database_instance.datasource_instance.name
  password = var.datasource_password
}
