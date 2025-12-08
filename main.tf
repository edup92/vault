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
