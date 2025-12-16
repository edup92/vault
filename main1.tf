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

resource "google_cloud_run_v2_service" "service" {
  name     = local.service_name
  project  = var.gcloud_project_id
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  template {
    containers {
      image = local.service_image
      ports {
        container_port = local.service_port
      }
      env { name = "DOMAIN" value = "https://${var.dns_record}" }
      env { name = "ROCKET_PORT" value = "${local.service_port}" }
      env { name = "ROCKET_ADDRESS" value = "0.0.0.0" }
      env { name = "SIGNUPS_ALLOWED" value = "false" }
      env { name = "INVITATIONS_ALLOWED" value = "false" }
      env { name = "WEBSOCKET_ENABLED" value = "true" }
      env { name = "WEB_VAULT_ENABLED" value = "true" }
      env { name = "ADMIN_TOKEN" value = var.admin_pass }
      env { name = "TZ" value = "Europe/Madrid" }
      env { name = "SMTP_HOST" value = var.smtp_host }
      env { name = "SMTP_FROM" value = var.smtp_username }
      env { name = "SMTP_PORT" value = var.smtp_port }
      env { name = "SMTP_SECURITY" value = var.smtp_security }
      env { name = "SMTP_USERNAME" value = var.smtp_username }
      env { name = "SMTP_PASSWORD" value = var.smtp_password }
      env { name  = "DATABASE_URL" value = "postgresql://vaultwarden:${var.db_password}@/vaultwarden?host=/cloudsql/${google_sql_database_instance.sql_main.connection_name}"}
      resources {
        limits = {
          cpu    = local.service_cpu
          memory = local.service_memory
        }
      }
    }
    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }
    cloud_sql_instances = [
      google_sql_database_instance.sql_main.connection_name
    ]
  }
}