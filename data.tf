data "google_compute_zones" "available" {
}

data "cloudflare_zone" "zone_main" {
  filter {
    name = var.dns_domain
  }
}

data "cloudflare_ip_ranges" "cloudflare" {}

data "cloudflare_rulesets" "zone_rulesets" {
  zone_id = data.cloudflare_zone.zone_main.id
}


data "cloudflare_rulesets" "waf_rulesets" {
  zone_id = data.cloudflare_zone.zone_main.id
}
