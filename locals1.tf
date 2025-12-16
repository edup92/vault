locals {
  # DB
  db_main_name = "${var.project_name}-sql-main"
  db_model = "db-f1-micro"
  db_type = "POSTGRES_15"
  db_name = "db_vault"
  db_user = "user_vault"

  # Service

  service_main_name = "${var.project_name}-service-main"
  service_cpu =  "0.25"
  service_memory = "256Mi"
  service_image = "vaultwarden/server:latest"
  service_port = 80

}