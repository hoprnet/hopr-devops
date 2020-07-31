locals {
  datacenter  = "ch"
  environment = "develop"
  prefix      = "${local.datacenter}-${local.environment}"
  bootstrap_servers = [
    "/ip4/34.65.164.158/tcp/9091/p2p/16Uiu2HAm3pjLi47JH6YdM4vFg4mVNxRs9epCEkjpMCYrVaFmKEzH",
    "/ip4/34.65.120.13/tcp/9091/p2p/16Uiu2HAkvW5BTEpiRHsroPcdY6A3qMUgei4xmoUFgjaQqtfLx1D7"
  ]
}

terraform {
  backend "gcs" {
    bucket = "hopr-ch-develop-node-terraform-state"
    prefix = "terraform/state"
  }
}

provider google {
  project = "hopr-${local.prefix}"
  region  = "europe-west6"
  version = "~> 3.0"
}

module "hopr-node" {
  instance_count    = 2
  instance_name     = "hopr-node"
  prefix            = local.prefix
  bootstrap_servers = local.bootstrap_servers
  is_bootstrap      = false

  env_ETHEREUM_PROVIDER = "wss://kovan.infura.io/ws/v3/f7240372c1b442a6885ce9bb825ebc36"
  env_HOST_IPV4         = "0.0.0.0:9091"
  env_DEBUG             = "hopr-core*"

  container_arguments = ["-p", "111111"]
  image_port          = "9091"

  source          = "../../../../modules/services/hopr"
  project_id      = "hopr-${local.prefix}"
  region          = "europe-west6"
  zone            = "europe-west6-a"
  client_email    = "terraform@hopr-${local.prefix}.iam.gserviceaccount.com"
  container_image = "gcr.io/hoprassociation/hopr-core:1.2.0"
  key             = "key.pub"
}

output "instances" {
  description = "The mapping between instances and their addresses"
  value       = module.hopr-node.instances
}
