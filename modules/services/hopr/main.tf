locals {
  instance_name = format("%s-%s", var.instance_name, substr(md5(module.hopr-container.container.image), 0, 8))
}

resource "google_compute_address" "static" {
  name = "${local.instance_name}-ipv4-address"
}

module "hopr-container" {
  source         = "terraform-google-modules/container-vm/google"
  version        = "2.0.0"
  cos_image_name = "cos-stable-81-12871-103-0"

  container = {
    image = var.container_image
    tty : true
    volumeMounts = [
      {
        mountPath = "/app/db"
        name      = "hopr-db"
        readOnly  = false
      }
    ]
    args = var.container_arguments
    env = [
      {
        name  = "HOST_IPV4"
        value = var.env_HOST_IPV4
      },
      {
        name  = "BOOTSTRAP_SERVERS"
        value = var.env_BOOTSTRAP_SERVERS
      },
      {
        name  = "ETHEREUM_PROVIDER"
        value = var.env_ETHEREUM_PROVIDER
      },
      {
        name  = "DEBUG"
        value = var.env_DEBUG
      }
    ]
  }

  volumes = [
    {
      name = "hopr-db"
      hostPath = {
        path = "/var/hopr/db"
      }
    }
  ]

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
    ssh-keys                  = "daneel:${file("${var.key}")}"
    gce-container-declaration = module.hopr-container.metadata_value
    google-logging-enabled    = "true"
    google-monitoring-enabled = "true"
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

resource "google_compute_firewall" "tcp-access" {
  name    = "${local.instance_name}-tcp"
  project = var.project_id
  network = "default"

  allow {
    protocol = "tcp"
    ports    = [var.image_port]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["hopr-container-vm"]
}
