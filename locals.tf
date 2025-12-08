locals {
  # Instances
  instance_main_name = "${var.project_name}-instance-main"
  instance_type      = "e2-micro"
  instance_os        = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2204-jammy-v20251204"
  disk_main_name     = "${var.project_name}-disk-main"
  disk_type          = "pd-balanced"
  snapshot_main_name = "${var.project_name}-snapshot-main"

  # LB
  instancegroup_main_name = "${var.project_name}-instancegroup-main"
  healthcheck_main_name = "${var.project_name}-healthcheck-main"
  backend_main_name = "${var.project_name}-backend-main"
  urlmap_main_name = "${var.project_name}-urlmap-main"
  ssl_main_name = "${var.project_name}-ssl-main"
  computetarget_main_name = "${var.project_name}-computetarget-main"
  ip_lb_name = "${var.project_name}-ip-lb"
  fr_lb_name = "${var.project_name}-forwadingrule-lb"

  # Secrets
  secret_pem_ssh = "${var.project_name}-secret-pem-ssh"

  # Network
  firewall_lb_name        = "${var.project_name}-firewall-lb"
  firewall_localssh_name  = "${var.project_name}-firewall-localssh"
  firewall_tempssh_name   = "${var.project_name}-firewall-tempssh"

  # Ansible
  ansible_null_resource = "./src/null_resources/ansible.sh"
  ansible_path          = "./src/ansible/install.yml"
  ansible_user          = "ubuntu"

  ansible_vars = jsonencode({
    dns_record          = var.dns_record
    admin_email         = var.admin_email
    admin_pass          = var.admin_pass
    smtp_host           = var.smtp_host
    smtp_security       = var.smtp_security
    smtp_port           = var.smtp_port
    smtp_username       = var.smtp_username
    smtp_password       = var.smtp_password
  })
}
