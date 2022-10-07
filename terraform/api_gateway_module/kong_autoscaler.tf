resource "google_compute_autoscaler" "gce_autoscaler" {
  name   = "api-gateway-autoscaler"
  zone   = var.instance_zone
  target = google_compute_instance_group_manager.gce_igm.self_link

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 2
    cooldown_period = 300

    cpu_utilization {
      target = 0.7
    }
  }
}
resource "google_compute_instance_group_manager" "gce_igm" {
  #provider = google-beta

  name               = "api-gateway-managed-ig"
  zone               = var.instance_zone
  base_instance_name = "api-gateway"

  version {
    instance_template = google_compute_instance_template.kong_node.self_link
    name              = "api-gateway"
  }
  named_port {
    name = "http8000"
    port = 8000
  }
  named_port {
    name = "http1337"
    port = 1337
  }
  target_pools = [google_compute_target_pool.gce_tp.self_link]
}

resource "google_compute_target_pool" "gce_tp" {
  provider = google-beta
  name     = "api-gateway-tp"
}