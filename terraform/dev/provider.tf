provider "google" {
  credentials = file("terraform-account.json")
  project     = "xxx"
  region      = "europe-west1"
}

provider "google-beta" {
  credentials = file("terraform-account.json")
  project     = "xxx"
  region      = "europe-west1"
}