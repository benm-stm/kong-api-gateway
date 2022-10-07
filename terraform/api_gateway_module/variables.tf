variable "env" {
  type        = string
  description = "deployment environment"
  default     = "dev"
}

variable "project" {
  type        = string
  description = "The gcp project id"
  default     = "xxx"
}

variable "managed_zone_name" {
  type        = string
  description = "Managed zone name"
  default     = "dev-gcp-digital-backbone-io"
}

variable "kong_admin_hlb_ssl_certificate_domain" {
  type        = string
  description = "Target domain name used in the ssl certificate"
  default     = "admin.api-gateway.dev.gcp.digital-backbone.io"
}

variable "region" {
  type        = string
  description = "The region of resources"
  default     = "europe-west1"
}

variable "dns_name" {
  type        = string
  description = "The DNS name of the ManagedZone"
  default     = "gcp.digital-backbone.io."
}

variable "kong_admin_hlb_port_range" {
  default = 443
}

variable "kong_hlb_ssl_certificate_domain" {
  type        = string
  description = "Target domain name used in the ssl certificate"
  default     = "api-gateway.dev.gcp.digital-backbone.io"
}

variable "kong_backend_hc_http_health_check" {
  description = "A HTTP Health Check port"
  default     = 8000
}

variable "kong_admin_backend_hc_http_health_check" {
  description = "A HTTP Health Check port"
  default     = 1337
}

variable "kong_node_instance_type" {
  type        = string
  description = "The machine type to create"
  default     = "n1-standard-4"
}

variable "instance_zone" {
  type        = string
  description = "The zone that the machine should be created in"
  default     = "europe-west1-b"
}

variable "instance_disk_image" {
  type        = string
  description = "The image from which to initialize the instance boot disk"
  default     = "centos-7"
}

variable "instance_ssh_keys" {
  type        = string
  description = "SSH keys that will be deployed on the instance, separated with'\n'"
  default     = "xxx"
}

variable "instance_scopes" {
  type        = list
  description = "A list of service scopes"
  default     = ["userinfo-email", "compute-ro", "storage-ro"]
}

variable "datasource_username" {
  type        = string
  description = "username of the datasource's postgres database"
}

variable "datasource_password" {
  type        = string
  description = "password of the datasource's postgres database"
}