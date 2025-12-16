# SQL

resource "google_sql_database_instance" "sql_main" {
  name             = local.db_main_name
  project = var.gcloud_project_id
  database_version = local.db_type
  settings {
    tier = local.db_model
    backup_configuration {
      enabled = true
    }
  }
  deletion_protection = false
}

resource "google_sql_database" "sqldb_main" {
  name     = local.db_name
  instance = google_sql_database_instance.sql_main.name
}

resource "google_sql_user" "sqluser_main" {
  name     = local.db_user
  instance = google_sql_database_instance.sql_main.name
  password = var.admin_pass
}

# Cloudrun

