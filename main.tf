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

module "gce-container" {
  source = "github.com/terraform-google-modules/terraform-google-container-vm.git"

  container = {
    image = "gcr.io/google-samples/hello-app:1.0"

    env = [
      {
        name  = "TEST_VAR"
        value = "Hello World!"
      },
    ]

    volumeMounts = [
      {
        mountPath = "/cache"
        name      = "tempfs-0"
        readOnly  = false
      },
    ]
  }

  volumes = [
    {
      name = "tempfs-0"

      emptyDir = {
        medium = "Memory"
      }
    },
  ]

  restart_policy = "Always"
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
    ssh-keys                  = "daneel:${file("key.pub")}"
    gce-container-declaration = module.gce-container.metadata_value
    google-logging-enabled    = "true"
    google-monitoring-enabled = "true"
  }

}

output "ip" {
  value = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
}

