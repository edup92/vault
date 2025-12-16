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

resource "google_cloud_run_v2_service" "service_main" {
  name     = local.service_main_name
  project  = var.gcloud_project_id
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  template {
    containers {
      image = local.service_image
      ports { container_port = local.service_port }
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

# LB

resource "google_compute_backend_service" "backend_main" {
  name                  = local.backend_name
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.healthcheck_main.self_link]
  connection_draining_timeout_sec = 10
  backend {
    group = google_compute_region_network_endpoint_group.neg.id
  }
  lifecycle {
    ignore_changes = [iap]         # <- clave para no deshabilitarlo
  }
}