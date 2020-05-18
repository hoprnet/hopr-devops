terraform {
  backend "gcs" {
    bucket = "hopr-terraform-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "hoprassociation"
  region  = "europe-west6"
}

resource "google_compute_address" "static" {
  name = "ipv4-address"
}

data "google_compute_image" "debian_image" {
  family  = "debian-9"
  project = "debian-cloud"
}

// A single Google Cloud Engine instance
resource "google_compute_instance" "default" {
  name         = "hopr-develop-eu-core-001-west6-a"
  machine_type = "f1-micro"
  zone         = "europe-west6-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian_image.self_link
    }
  }
  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }
  metadata = {
    ssh-keys = "daneel:${file("key.pub")}"
  }

}

output "ip" {
  value = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
}

