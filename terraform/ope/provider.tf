provider "google" {
  credentials = file("terraform-account.json")
  project     = "xxx-70132-ope-3917592"
  region      = "europe-west1"
}

provider "google-beta" {
  credentials = file("terraform-account.json")
  project     = "xxx-70132-ope-3917592"
  region      = "europe-west1"
}