# Vault

## Vaultwarden selfhosted in docker containers, with Google SSO Auth, Hosted in Google cloud

## Installation

- Create google account project
- Run bootstrap.sh on Cloudshell
- Paste json data from bootstrap.sh as Github Actions Secret with name SERVICE_ACCOUNT 
- Paste this json as Github Actions Secret with name VARS_JSON:

`{
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
}`

- Run Github Actions
- Go to https://console.cloud.google.com/security/iap?tab=applications&hl=es-419&project=MYPROJECT and enable IAP
- Click in the same window on the created backend, click on add principal, on principal write authorized email (x@gmail.com) and add the role "roles/iap.httpsResourceAccessor"
- Click in the same window on the created backend, click on configuration, set custom oauth, generate credentials and save
- Disable and enable IAP, check if works
- Add user to https://yourdomain.tld/admin/users/overview

- Debug: Check docker instances with: sudo docker ps
