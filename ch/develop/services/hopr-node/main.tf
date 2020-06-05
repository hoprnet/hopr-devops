locals {
  bootstrap_servers = [
    "/dns4/ch-test-01.hoprnet.io/tcp/9091/p2p/16Uiu2HAm2n7Lfn76Ex7JnesxXjCtoPbLA6S1Q3boEELETBCD9RKc",
    "/dns4/ch-test-02.hoprnet.io/tcp/9091/p2p/16Uiu2HAm9YbgfQ5yAPQ99ZgfCdJKcdn7tZ2xDBwvaaitfvXGgD2d",
    "/dns4/ch-test-03.hoprnet.io/tcp/9091/p2p/16Uiu2HAmSDWT1xhYc7CYEunDoVY21aWA5LpXTTqZpxymFB34FFjH",
    "/ip4/34.65.200.251/tcp/9091/p2p/16Uiu2HAm2n7Lfn76Ex7JnesxXjCtoPbLA6S1Q3boEELETBCD9RKc",
    "/ip4/34.65.51.50/tcp/9091/p2p/16Uiu2HAm9YbgfQ5yAPQ99ZgfCdJKcdn7tZ2xDBwvaaitfvXGgD2d",
    "/ip4/34.65.69.119/tcp/9091/p2p/16Uiu2HAmSDWT1xhYc7CYEunDoVY21aWA5LpXTTqZpxymFB34FFjH"
  ]
}

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

module "hopr-node" {
  instance_count    = 5
  instance_name     = "hopr-node"
  prefix            = "ch-develop"
  bootstrap_servers = local.bootstrap_servers
  is_bootstrap      = false

  env_ETHEREUM_PROVIDER = "wss://kovan.infura.io/ws/v3/f7240372c1b442a6885ce9bb825ebc36"
  env_HOST_IPV4         = "0.0.0.0:9091"
  env_DEBUG             = "hopr-core*"

  container_arguments = ["-p", "111111"]
  image_port          = "9091"

  source          = "../../../../modules/services/hopr"
  project_id      = "hopr-ch-develop"
  region          = "europe-west6"
  zone            = "europe-west6-a"
  client_email    = "terraform@hopr-ch-develop.iam.gserviceaccount.com"
  container_image = "gcr.io/hoprassociation/hopr-core:testnet-0af75cb"
  key             = "key.pub"
}

output "instances" {
  description = "The mapping between instances and their addresses"
  value       = module.hopr-node.instances
}
