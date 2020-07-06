locals {
  datacenter  = "ch"
  environment = "develop"
  prefix      = "${local.datacenter}-${local.environment}"
}

terraform {
  backend "gcs" {
    bucket = "hopr-ch-develop-libp2p-webrtc-star-terraform-state"
    prefix = "terraform/state"
  }
}

provider google {
  project = "hopr-${local.prefix}"
  region  = "europe-west6"
  version = "~> 3.0"
}

module "libp2p-webrtc-star" {
  instance_count = 2
  instance_name  = "libp2p-webrtc-star"
  prefix         = local.prefix

  source     = "../../../../modules/services/libp2p-webrtc-star"
  image_port = "9090"

  project_id      = "hopr-${local.prefix}"
  region          = "europe-west6"
  zone            = "europe-west6-a"
  client_email    = "terraform@hopr-${local.prefix}.iam.gserviceaccount.com"
  container_image = "libp2p/js-libp2p-webrtc-star"
  key             = "key.pub"
}

output "instances" {
  description = "The mapping between instances and their addresses"
  value       = module.libp2p-webrtc-star.instances
}
