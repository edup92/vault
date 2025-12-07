

variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "bitwarden"
}

variable "gcloud_project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "gcloud_region" {
  description = "Google Cloud region where resources will be deployed"
  type        = string
}

variable "cf_token" {
  description = "Cloudflare Token"
  type        = string
}

variable "cf_accountid" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "dns_domain" {
  description = "Fully Qualified Domain Name (FQDN) "
  type        = string
}

variable "dns_record" {
  description = "DNS record"
  type        = string
}

variable "allowed_countries" {
  description = "List of allowed countries for access control"
  type        = list(string)
  default     = []
}

variable "admin_email" {
  description = "Administrator email address for the Vaultwarden instance"
  type        = string
}

variable "oauth_client_id" {
  description = "OAuth client ID for Google SSO authentication"
  type        = string
}

variable "oauth_client_secret" {
  description = "OAuth client secret for Google SSO authentication"
  type        = string
  sensitive   = true
}

variable "admin_pass" {
  description = "Password for vaultwarden ADMIN"
  type        = string
  sensitive   = true
}

variable "smtp_host" {
  description = "SMTP server hostname for email delivery"
  type        = string
}

variable "smtp_port" {
  description = "SMTP server port for email delivery"
  type        = number
}

variable "smtp_security" {
  description = "SMTP server security type"
  type        = string
}

variable "smtp_username" {
  description = "SMTP server username for authentication"
  type        = string
}

variable "smtp_password" {
  description = "SMTP server password for authentication"
  type        = string
  sensitive   = true
}
