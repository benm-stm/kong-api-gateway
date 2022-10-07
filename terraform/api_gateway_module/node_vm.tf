data "template_file" "kong_node" {
  template = file("${path.module}/startup_scripts/kong_node")
  vars = {
    datasource_address  = google_sql_database_instance.datasource_instance.ip_address.0.ip_address
    datasource_user     = var.datasource_username
    datasource_password = var.datasource_password
  }
}
resource "google_compute_instance_template" "kong_node" {
  provider = google-beta

  name           = "kong-node"
  region         = var.region
  machine_type   = var.kong_node_instance_type
  can_ip_forward = false
  tags           = ["fw-ssh-vms-${var.env}", "fw-tags", "${var.env}"]

  disk {
    source_image = var.instance_disk_image
  }

  network_interface {
    subnetwork         = local.subnetwork.name
    subnetwork_project = local.subnetwork.project
  }

  metadata = {
    sshKeys        = var.instance_ssh_keys
    startup-script = data.template_file.kong_node.rendered
  }

  service_account {
    scopes = var.instance_scopes
  }
}
