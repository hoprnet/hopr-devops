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
  bootstrap_servers = "/ip4/34.65.237.196/tcp/9091/p2p/16Uiu2HAmVQNGuAyitMWHmuJ1UTyeBALyiv9KthDgAupAug8eRv7c,/ip4/34.65.119.138/tcp/9091/p2p/16Uiu2HAmUx59dXE9GgxaXW68sFhS3MdJcvZomSWkDU28J7DacHWW"
}

module "hopr-node-001" {
  instance_name = "hopr-ch-develop-node-001"

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
  container_image = "gcr.io/hoprassociation/hopr-core:0.0.1"
  key             = "key.pub"
}

module "hopr-node-002" {
  instance_name = "hopr-ch-develop-node-002"

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
  container_image = "gcr.io/hoprassociation/hopr-core:0.0.1"
  key             = "key.pub"
}

module "hopr-node-003" {
  instance_name = "hopr-ch-develop-node-003"

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
  container_image = "gcr.io/hoprassociation/hopr-core:0.0.1"
  key             = "key.pub"
}

module "hopr-node-004" {
  instance_name = "hopr-ch-develop-node-004"

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
  container_image = "gcr.io/hoprassociation/hopr-core:0.0.1"
  key             = "key.pub"
}

module "hopr-node-005" {
  instance_name = "hopr-ch-develop-node-005"

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
  container_image = "gcr.io/hoprassociation/hopr-core:0.0.1"
  key             = "key.pub"
}

output "ipv4-node-001" {
  description = "The public IP address of the deployed instance"
  value       = module.hopr-node-001.ipv4
}
output "ipv4-node-002" {
  description = "The public IP address of the deployed instance"
  value       = module.hopr-node-002.ipv4
}
output "ipv4-node-003" {
  description = "The public IP address of the deployed instance"
  value       = module.hopr-node-003.ipv4
}
output "ipv4-node-004" {
  description = "The public IP address of the deployed instance"
  value       = module.hopr-node-004.ipv4
}
output "ipv4-node-005" {
  description = "The public IP address of the deployed instance"
  value       = module.hopr-node-005.ipv4
}