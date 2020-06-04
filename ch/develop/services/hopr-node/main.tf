terraform {
  backend "gcs" {
    bucket = "hopr-ch-develop-terraform-state"
    prefix = "terraform/state-nodes"
  }
}

provider google {
  project = "hopr-ch-develop"
  region  = "europe-west6"
  version = "~> 3.0"
}

locals {
  bootstrap_servers = "/ip4/34.65.92.146/tcp/9091/p2p/16Uiu2HAm5HEoRMUSD5fjofEEDRyxhY4hCAwmYgphdF1TPUnzHgNz,/ip4/34.65.237.196/tcp/9091/p2p/16Uiu2HAmHFq9BJS1sxPxo9Bn5A6TEedpCuf6izpX2rA5QDg6qFZa"
}

module "hopr-node" {
  instance_count = 5
  instance_name  = "hopr-node"
  prefix         = "ch-develop"

  env_ETHEREUM_PROVIDER = "wss://kovan.infura.io/ws/v3/f7240372c1b442a6885ce9bb825ebc36"
  env_HOST_IPV4         = "0.0.0.0:9091"
  env_BOOTSTRAP_SERVERS = local.bootstrap_servers
  env_DEBUG             = "hopr-core*"

  container_arguments = ["-p", "111111"]
  image_port          = "9091"

  source          = "../../../../modules/services/hopr"
  project_id      = "hopr-ch-develop"
  region          = "europe-west6"
  zone            = "europe-west6-a"
  client_email    = "terraform@hopr-ch-develop.iam.gserviceaccount.com"
  container_image = "gcr.io/hoprassociation/hopr-core:nat-traversal-rc"
  key             = "key.pub"
}

output "instances" {
  description = "The mapping between instances and their addresses"
  value       = module.hopr-node.instances
}