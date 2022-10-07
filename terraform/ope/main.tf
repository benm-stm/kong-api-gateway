module "ope" {
  source                                = "../api_gateway_module"
  env                                   = "ope"
  project                               = "xxx-70132-ope-3917592"
  managed_zone_name                     = "ope-gcp-digital-backbone-io"
  kong_admin_hlb_ssl_certificate_domain = "admin.api-gateway.ope.gcp.digital-backbone.io"
  kong_hlb_ssl_certificate_domain       = "api-gateway.ope.gcp.digital-backbone.io"
  datasource_username                   = var.datasource_username
  datasource_password                   = var.datasource_password
}

variable "datasource_username" {
  type        = string
  description = "username of the datasource's postgres database"
}

variable "datasource_password" {
  type        = string
  description = "password of the datasource's postgres database"
}