terraform {
  backend "gcs" {
    bucket      = "tfstate-ope"
    prefix      = "terraform-api-gateway"
    credentials = "terraform-account.json"
  }
  required_version  = ">=1.1.9"
}

data "terraform_remote_state" "host" {
  backend = "gcs"

  config = {
    bucket      = "tfstate-hostproject"
    prefix      = "terraform"
    credentials = "terraform-account.json"
  }
}
