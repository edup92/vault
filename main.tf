# SSH Key

resource "tls_private_key" "pem_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_secret_manager_secret" "secret_pem_ssh" {
  secret_id = local.secret_pem_ssh
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "secretversion_pem_ssh" {
  secret      = google_secret_manager_secret.secret_pem_ssh.id
  secret_data = jsonencode({
    private_key = tls_private_key.pem_ssh.private_key_pem
    public_key  = tls_private_key.pem_ssh.public_key_openssh
  })
}

resource "google_compute_project_metadata" "metadata_keypair" {
  project = var.gcloud_project_id
  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.pem_ssh.public_key_openssh}"
  }
}

# Instance

resource "google_compute_instance" "instance_main" {
  name         = local.instance_main_name
  project      = var.gcloud_project_id
  machine_type = local.instance_type
  zone          = data.google_compute_zones.available.names[0]
  metadata = {
    enable-osconfig = "TRUE"
  }
  allow_stopping_for_update = true
  boot_disk {
    auto_delete = false
    device_name = local.disk_main_name
    initialize_params {
      image = local.instance_os
      type  = local.disk_type
    }
  }
  network_interface {
    network = "default"
    access_config {
      network_tier = "STANDARD"
    }
    stack_type = "IPV4_ONLY"
  }
  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
  scheduling {
    provisioning_model = "STANDARD"
    on_host_maintenance = "MIGRATE"
  }
  labels = {
    goog-ec-src = "vm_add-gcloud"
  }
  reservation_affinity {
    type = "NO_RESERVATION"
  }
  tags = [local.instance_main_name]
}

# Snapshot

resource "google_compute_resource_policy" "snapshot_policy" {
  name   = local.snapshot_main_name
  project = var.gcloud_project_id
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "00:00"
      }
    }
    retention_policy {
      max_retention_days    = 31
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "disk_policy_attachment" {
  name    = google_compute_resource_policy.snapshot_policy.name
  disk    = google_compute_instance.instance_main.name
  zone    = data.google_compute_zones.available.names[0]
  project = var.gcloud_project_id

  depends_on = [google_compute_instance.instance_main]
}

# Firewall

resource "google_compute_firewall" "fw_localssh" {
  name    = local.firewall_localssh_name
  project = var.gcloud_project_id
  network = "default"
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags   = [google_compute_instance.instance_main.name]
}

resource "google_compute_firewall" "fw_lb" {
  name    = local.firewall_lb_name
  project = var.gcloud_project_id
  network = "default"
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  source_ranges = ["35.191.0.0/16","130.211.0.0/22"]
  target_tags   = [google_compute_instance.instance_main.name]
}

resource "google_compute_firewall" "fw_tempssh" {
  name    = local.firewall_tempssh_name
  project = var.gcloud_project_id
  network = "default"
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [google_compute_instance.instance_main.name]
  disabled = true
}

# LB

resource "google_compute_instance_group" "instancegroup_main" {
  name        = local.instancegroup_main_name
  zone    = data.google_compute_zones.available.names[0]
  instances = [google_compute_instance.instance_main.self_link]
  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_health_check" "healthcheck_main" {
  name                = local.healthcheck_main_name
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_backend_service" "backend_main" {
  name                  = local.backend_main_name
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_health_check.healthcheck_main.self_link]
  connection_draining_timeout_sec = 10
  backend {
    group = google_compute_instance_group.instancegroup_main.self_link
  }
 # iap {
 #   oauth2_client_id     = google_iap_client.iap_client.client_id
 #   oauth2_client_secret = google_iap_client.iap_client.secret
 # }
}

resource "google_compute_url_map" "urlmap_main" {
  name            = local.urlmap_main_name
  default_service = google_compute_backend_service.backend_main.self_link
}

resource "google_compute_managed_ssl_certificate" "ssl_main" {
  name = local.ssl_main_name
  managed {
    domains = [var.dns_record]
  }
}

resource "google_compute_target_https_proxy" "computetarget_main" {
  name             = local.computetarget_main_name
  url_map          = google_compute_url_map.urlmap_main.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_main.self_link]
}

resource "google_compute_global_address" "ip_lb" {
  name = local.ip_lb_name
}

resource "google_compute_global_forwarding_rule" "fr_main" {
  name                  = local.fr_lb_name
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.computetarget_main.self_link
  ip_address            = google_compute_global_address.ip_lb.address
}

#resource "google_iap_web_backend_service_iam_member" "iap_access" {
#  project              = var.gcloud_project_id
#  web_backend_service = google_compute_backend_service.backend_main.name
#  role                = "roles/iap.httpsResourceAccessor"
#  member              = "user:${var.admin_email}"
#}

# Playbook

resource "null_resource" "null_ansible_install" {
  depends_on = [
    tls_private_key.pem_ssh,
    google_compute_instance.instance_main,
    google_compute_firewall.fw_tempssh,
  ]
  triggers = {
    instance_id   = google_compute_instance.instance_main.id
    playbook_hash = filesha256(local.ansible_path)
  }
  provisioner "local-exec" {
    environment = {
      PROJECT_ID    = var.gcloud_project_id
      INSTANCE_IP    = google_compute_instance.instance_main.network_interface[0].access_config[0].nat_ip
      INSTANCE_USER  = local.ansible_user
      INSTANCE_SSH_KEY = nonsensitive(tls_private_key.pem_ssh.private_key_pem)
      FW_TEMPSSH_NAME  = google_compute_firewall.fw_tempssh.name
      VARS_JSON = nonsensitive(local.ansible_vars)
      PLAYBOOK_PATH = local.ansible_path
    }
    command = local.ansible_null_resource
  }
}

# Outpupts

output "output_ip" {
  description = "Global IPv4 assigned to the HTTPS load balancer"
  value       = google_compute_global_address.ip_lb.address
}