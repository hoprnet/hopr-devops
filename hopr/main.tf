locals {
  instance_name = format("%s-%s", var.instance_name, substr(md5(module.hopr-container.container.image), 0, 8))
}

resource "google_compute_address" "static" {
  name = "ipv4-address"
}

module "hopr-container" {
  source         = "terraform-google-modules/container-vm/google"
  version        = "2.0.0"
  cos_image_name = var.cos_image_name

  container = {
    image = var.container_image
    env = [
      {
        name  = "TEST_VAR"
        value = var.env_welcome
      },
    ]
  }

  restart_policy = "Always"
}

resource "google_compute_instance" "vm" {
  project      = var.project_id
  name         = local.instance_name
  machine_type = "g1-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = module.hopr-container.source_image
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  tags = ["hopr-container-vm"]

  metadata = {
    ssh-keys                  = "daneel:${file("../key.pub")}"
    gce-container-declaration = module.hopr-container.metadata_value
  }

  labels = {
    container-vm = module.hopr-container.vm_container_label
  }

  service_account {
    email = var.client_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

resource "google_compute_firewall" "http-access" {
  name    = "${local.instance_name}-http"
  project = var.project_id
  network = "default"

  allow {
    protocol = "tcp"
    ports    = [var.image_port]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["hopr-container-vm"]
}
