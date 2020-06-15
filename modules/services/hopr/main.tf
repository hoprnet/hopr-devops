locals {
  instance_name = format("%s-%s", var.instance_name, substr(md5(module.hopr-container.container.image), 0, 8))
  prefix        = var.prefix == "" ? "" : "${var.prefix}-"
}

resource "google_compute_address" "static" {
  count       = var.instance_count
  project     = var.project_id
  description = "Terraform-Managed."
  region      = var.region
  name        = "${local.prefix}${local.instance_name}-${format("%d", count.index + 1)}"
}

module "hopr-container" {
  source         = "terraform-google-modules/container-vm/google"
  version        = "2.0.0"
  cos_image_name = "cos-dev-84-13078-0-0"

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
        value = var.is_bootstrap ? "" : var.bootstrap_servers[var.instance_count]
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
  count        = var.instance_count
  name         = "${local.prefix}${local.instance_name}-${count.index + 1}"
  description  = "Terraform-Managed."
  project      = var.project_id
  machine_type = var.machine_type
  zone         = var.zone

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  boot_disk {
    initialize_params {
      image = module.hopr-container.source_image
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static.*.address[count.index]
    }
  }

  tags = ["hopr-container-vm"]

  metadata = {
    ssh-keys                  = "daneel:${file("${var.key}")}"
    gce-container-declaration = module.hopr-container.metadata_value
    google-logging-enabled    = "true"
    google-monitoring-enabled = "true"
  }

  # Adding manually the missing iptables rule for allowing outside access to HOPR node
  metadata_startup_script = "iptables -A INPUT -p tcp --dport ${var.image_port} -j ACCEPT"

  labels = {
    container-vm = module.hopr-container.vm_container_label
  }

  service_account {
    email = var.client_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/pubsub",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }
}
resource "google_compute_firewall" "tcp-access" {
  name    = "${local.prefix}${local.instance_name}-tcp"
  project = var.project_id
  network = "default"

  allow {
    protocol = "tcp"
    ports    = [var.image_port]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["hopr-container-vm"]
}
