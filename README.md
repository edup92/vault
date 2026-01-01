# Vault

## Vaultwarden selfhosted in docker containers, with Tailscale, Hosted in Google cloud

## Installation

- Create google account project
- Run bootstrap.sh on Cloudshell
- Paste json data from bootstrap.sh as Github Actions Secret with name SERVICE_ACCOUNT 
- Paste this json as Github Actions Secret with name VARS_JSON:

`{
  "gcloud_project_id":"",
  "gcloud_region":"",
  "project_name": "myproject",
  "tailscale_key": "",
  "dns_record": "x.mydomain.tld",
  "admin_email": "",
  "admin_pass": "",
  "smtp_host": "",
  "smtp_port": 587,
  "smtp_security": "starttls",
  "smtp_username": "",
  "smtp_password": "",
  "oauth_client_id": "",
  "oauth_client_secret": ""
}`

- Run Github Actions

- Debug: Check docker instances with: sudo docker ps
