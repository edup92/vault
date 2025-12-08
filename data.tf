data "google_compute_zones" "available" {
}

data "cloudflare_zone" "cf_zone" {
  name = var.dns_domain
}

data "cloudflare_ip_ranges" "cf_ip" {}

data "cloudflare_rulesets" "zone_rulesets" {
  zone_id = data.cloudflare_zone.cf_zone.id
}


data "cloudflare_rulesets" "zone_waf" {
  zone_id = data.cloudflare_zone.cf_zone.id
}
