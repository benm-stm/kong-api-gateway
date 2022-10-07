module "dev" {
  source              = "../api_gateway_module"
  datasource_username = var.datasource_username
  datasource_password = var.datasource_password
}
variable "datasource_username" {
  type        = string
  description = "username of the datasource's postgres database"
}

variable "datasource_password" {
  type        = string
  description = "password of the datasource's postgres database"
}
