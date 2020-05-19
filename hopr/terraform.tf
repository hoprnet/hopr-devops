terraform {
  backend "gcs" {
    bucket = "hopr-ch-develop-terraform-state"
    prefix = "terraform/state"
  }
}
