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

resource "google_compute_firewall" "fw_cf" {
  name    = local.firewall_cf_name
  project = var.gcloud_project_id
  network = "default"
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  source_ranges = data.cloudflare_ip_ranges.cloudflare.ipv4_cidr_blocks
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

# Cloudflare

resource "cloudflare_dns_record" "dnsrecord_main" {
  zone_id = data.cloudflare_zone.zone_main.zone_id
  name    = var.dns_record
  type    = "A"
  content = google_compute_instance.instance_main.network_interface[0].access_config[0].nat_ip
  ttl     = 1
  proxied = true
  allow_overwrite = true
}

resource "cloudflare_zone_settings" "zonesettings_main" {
  zone_id = data.cloudflare_zone.zone_main.zone_id
  settings {
    ssl                     = "full"
    min_tls_version         = "1.2"
    automatic_https_rewrites = true
    always_use_https        = true
  }
}

resource "cloudflare_ruleset" "ruleset_cache" {
  zone_id = data.cloudflare_zone.zone_main.zone_id
  name    = "disable_cache_everything"
  kind    = "zone"
  phase   = "http_request_cache_settings"
  rules {
    enabled     = true
    description = "Soft disable cache (Terraform-safe)"
    expression  = "true"

    action = "set_cache_settings"

    action_parameters {
      cache = false
    }
  }
}

resource "cloudflare_ruleset" "ruleset_waf" {
  zone_id = data.cloudflare_zone.zone_main.zone_id
  name    = "country-access-control"
  kind    = "zone"
  phase   = "http_request_firewall_custom"
  rules {
    enabled     = true
    description = "Block all non-allowed countries"

    expression = "not (${join(" or ", [
      for c in var.allowed_countries :
      "(ip.geoip.country eq \"${c}\")"
    ])})"

    action = "block"
  }
}

resource "cloudflare_zero_trust_organization" "zerotrust_org" {
  account_id  = var.cf_accountid
  name        = local.zerotrust_name
  auth_domain = var.zerotrust_record
}