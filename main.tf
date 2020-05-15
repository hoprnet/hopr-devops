terraform {
  backend "gcs" {
    bucket  = "hopr-terraform-state"
    prefix  = "terraform/state"
  }
}

provider "google" {
  project = "hoprassociation"
  region  = "europe-west6"
}

// A single Google Cloud Engine instance
resource "google_compute_instance" "default" {
  name         = "hopr-develop-eu-core-001-west6-a"
  machine_type = "f1-micro"
  zone         = "europe-west6-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    network = "default"
    access_config {
      // Include this section to give the VM an external ip address
    }
  }
}
