locals {
  datacenter  = "ch"
  environment = "testing"
  prefix      = "${local.datacenter}-${local.environment}"
}


terraform {
  backend "gcs" {
    bucket = "hopr-ch-testing-terraform-state"
    prefix = "terraform/state-bootstrap"
  }
}

provider google {
  project = "hopr-${local.prefix}"
  region  = "europe-west6"
  version = "~> 3.0"
}

module "hopr-node-bootstrap" {
  instance_count    = 3
  instance_name     = "hopr-bootstrap"
  prefix            = local.prefix
  bootstrap_servers = []
  is_bootstrap      = true

  env_ETHEREUM_PROVIDER = "wss://kovan.infura.io/ws/v3/f7240372c1b442a6885ce9bb825ebc36"
  env_HOST_IPV4         = "0.0.0.0:9091"
  env_DEBUG             = "hopr-core*"

  container_arguments = ["-b", "-p", "111111"]
  image_port          = "9091"

  source          = "../../../../modules/services/hopr"
  project_id      = "hopr-${local.prefix}"
  region          = "europe-west6"
  zone            = "europe-west6-a"
  client_email    = "terraform@hopr-${local.prefix}.iam.gserviceaccount.com"
  container_image = "gcr.io/hoprassociation/hopr-core:testnet-0af75cb"
  key             = "key.pub"
}

output "instances" {
  description = "The mapping between instances and their addresses"
  value       = module.hopr-node-bootstrap.instances
}