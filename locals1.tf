locals {
  # DB
  db_main_name = "${var.project_name}-sql-main"
  db_model = "db-f1-micro"
  db_type = "POSTGRES_15"
  db_name = "db_vault"
  db_user = "user_vault"

}