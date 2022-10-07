# SSL policy
resource "google_compute_ssl_policy" "api_gateway_hlb_ssl_policy" {
  name            = "admin-api-gateway-ssl-policy"
  profile         = "RESTRICTED"
  min_tls_version = "TLS_1_2"
}

# reserved IP address
resource "google_compute_global_address" "api_gateway_global_ip" {
  name         = "ip-api-gateway"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

# certificate secrets are created and managed by Google
resource "google_compute_managed_ssl_certificate" "kong_admin_hlb_ssl_certificate" {
  provider = google-beta
  name     = "kong-admin-api-gateway-ssl-certificate"

  managed {
    domains = [var.kong_admin_hlb_ssl_certificate_domain]
  }
}
resource "google_compute_managed_ssl_certificate" "kong_hlb_ssl_certificate" {
  provider = google-beta
  name     = "kong-api-gateway-ssl-certificate"

  managed {
    domains = [var.kong_hlb_ssl_certificate_domain]
  }
}

# route incoming HTTPS requests to a URL map
resource "google_compute_target_https_proxy" "api_gateway_hlb_target_https_proxy" {
  name    = "kong-admin-api-gateway-https-proxy"
  url_map = google_compute_url_map.api_gateway_hlb_url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.kong_admin_hlb_ssl_certificate.self_link,
    google_compute_managed_ssl_certificate.kong_hlb_ssl_certificate.self_link
  ]
  ssl_policy = google_compute_ssl_policy.api_gateway_hlb_ssl_policy.self_link
}

# forwarding rule
resource "google_compute_global_forwarding_rule" "api_gateway_hlb_api_gateway" {
  name       = "kong-admin-hlb-api-gateway"
  ip_address = google_compute_global_address.api_gateway_global_ip.address
  target     = google_compute_target_https_proxy.api_gateway_hlb_target_https_proxy.self_link
  port_range = var.kong_admin_hlb_port_range
}

# url map
resource "google_compute_url_map" "api_gateway_hlb_url_map" {
  name            = "api-gateway-url-map"
  default_service = google_compute_backend_service.kong_hlb_backend.self_link

  host_rule {
    hosts        = [var.kong_hlb_ssl_certificate_domain]
    path_matcher = "kong"
  }

  host_rule {
    hosts        = [var.kong_admin_hlb_ssl_certificate_domain]
    path_matcher = "konga"
  }

  path_matcher {
    name            = "konga"
    default_service = google_compute_backend_service.kong_admin_hlb_backend.self_link
  }

  path_matcher {
    name            = "kong"
    default_service = google_compute_backend_service.kong_hlb_backend.self_link
  }
}

# backend service with custom request and response headers
resource "google_compute_backend_service" "kong_admin_hlb_backend" {
  name        = "kong-admin-api-gateway-backend"
  port_name   = "http1337"
  protocol    = "HTTP"
  timeout_sec = 30
  backend {
    #group       = google_compute_instance_group.kong_ig_api_gateway.self_link
    group = google_compute_instance_group_manager.gce_igm.instance_group
  }
  health_checks = [google_compute_health_check.kong_admin_backend_hc.self_link]
}

# backend service with custom request and response headers
resource "google_compute_backend_service" "kong_hlb_backend" {
  name        = "kong-api-gateway-backend"
  port_name   = "http8000"
  protocol    = "HTTP"
  timeout_sec = 30
  backend {
    #group       = google_compute_instance_group.kong_ig_api_gateway.self_link
    group = google_compute_instance_group_manager.gce_igm.instance_group
  }
  health_checks = [google_compute_health_check.kong_backend_hc.self_link]
}

resource "google_dns_record_set" "kong_admin_hlb_dns_node" {
  name         = "admin.api-gateway.${var.env}.${var.dns_name}"
  managed_zone = var.managed_zone_name
  type         = "A"
  ttl          = 5
  rrdatas      = [google_compute_global_address.api_gateway_global_ip.address]
}

resource "google_dns_record_set" "kong_hlb_dns_node" {
  name         = "api-gateway.${var.env}.${var.dns_name}"
  managed_zone = var.managed_zone_name
  type         = "A"
  ttl          = 5
  rrdatas      = [google_compute_global_address.api_gateway_global_ip.address]
}

# health check
resource "google_compute_health_check" "kong_admin_backend_hc" {
  name                = "kong-admin-api-gateway-backend-hc"
  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
  http_health_check {
    port         = var.kong_admin_backend_hc_http_health_check
    request_path = "/"
  }
}
resource "google_compute_health_check" "kong_backend_hc" {
  name                = "kong-api-gateway-backend-hc"
  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
  http_health_check {
    port         = var.kong_backend_hc_http_health_check
    request_path = "/health-check"
  }
}