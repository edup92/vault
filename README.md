# Vault

## Vaultwarden selfhosted in docker containers, with Google SSO Auth, Hosted in Google cloud

## Installation

1 - Create google account project
2 -  Run bootstrap.sh on Cloudshell
3 - Paste json data from bootstrap.sh as Github Actions Secret with name SERVICE_ACCOUNT 
4 - Paste this json as Github Actions Secret with name VARS_JSON:

{
  "gcloud_project_id":"",
  "gcloud_region":"",
  "project_name": "myproject",
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
}

- 5 Run Github Actions
- 6 Go to https://console.cloud.google.com/security/iap?tab=applications&hl=es-419&project=MYPROJECT and enable IAP
- 7 Click in the same window on the created backend, click on add principal, on principal write authorized email (x@gmail.com) and add the role "roles/iap.httpsResourceAccessor"
- 8 Click in the same window on the created backend, click on configuration, set custom oauth, generate credentials and save
- 9 Disable and enable IAP, check if works
- 10 Add user to https://yourdomain.tld/admin/users/overview

- Debug: Check docker instances with: sudo docker ps
