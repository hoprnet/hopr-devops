locals {
  datacenter  = "ch"
  environment = "develop"
  prefix      = "${local.datacenter}-${local.environment}"
  bootstrap_servers = [
    "/ip4/34.65.237.196/tcp/9091/p2p/16Uiu2HAmTr2MZhwzBH5VwsQDnw4nZHPouXycjmTEazkv3hfJC9nJ",
    "/ip4/34.65.69.76/tcp/9091/p2p/16Uiu2HAkwmkw2JbNWqU9sVfyeEzFF9nm3vB9Ag4SkVjBDjEA3bis",
    "/ip4/34.65.75.45/tcp/9091/p2p/16Uiu2HAkxfZ2GaSFtevoLCaDba5G6mypFF5JG686bzSTLZdLdsfR"
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
  instance_count    = 3
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
  container_image = "hopr/chat"
  key             = "key.pub"
}

output "instances" {
  description = "The mapping between instances and their addresses"
  value       = module.hopr-node.instances
}
