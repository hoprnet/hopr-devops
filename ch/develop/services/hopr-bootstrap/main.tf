terraform {
  backend "gcs" {
    bucket = "hopr-ch-develop-terraform-state"
    prefix = "terraform/state-bootstrap"
  }
}

provider google {
  project = "hopr-ch-develop"
  region  = "europe-west6"
  version = "~> 3.0"
}

module "hopr-node-bootstrap-001" {
  instance_name = "hopr-ch-develop-bootstrap-001"

  env_ETHEREUM_PROVIDER = "wss://kovan.infura.io/ws/v3/f7240372c1b442a6885ce9bb825ebc36"
  env_HOST_IPV4         = "0.0.0.0:9091"
  env_BOOTSTRAP_SERVERS = ""
  env_DEBUG             = "hopr-core*"

  container_arguments = ["-b", "-p", "111111"]
  image_port          = "9091"

  source          = "../../../../modules/services/hopr"
  project_id      = "hopr-ch-develop"
  region          = "europe-west6"
  zone            = "europe-west6-a"
  client_email    = "terraform@hopr-ch-develop.iam.gserviceaccount.com"
  container_image = "gcr.io/hoprassociation/hopr-core:libp2p-tcp"
  key             = "key.pub"
}

module "hopr-node-bootstrap-002" {
  instance_name = "hopr-ch-develop-bootstrap-002"

  env_ETHEREUM_PROVIDER = "wss://kovan.infura.io/ws/v3/f7240372c1b442a6885ce9bb825ebc36"
  env_HOST_IPV4         = "0.0.0.0:9091"
  env_BOOTSTRAP_SERVERS = ""
  env_DEBUG             = "hopr-core*"

  container_arguments = ["-b", "-p", "111111"]
  image_port          = "9091"

  source          = "../../../../modules/services/hopr"
  project_id      = "hopr-ch-develop"
  region          = "europe-west6"
  zone            = "europe-west6-a"
  client_email    = "terraform@hopr-ch-develop.iam.gserviceaccount.com"
  container_image = "gcr.io/hoprassociation/hopr-core:libp2p-tcp"
  key             = "key.pub"
}

output "ipv4-bootstrap-001" {
  description = "The public IP address of the deployed instance"
  value       = module.hopr-node-bootstrap-001.ipv4
}

output "ipv4-bootstrap-002" {
  description = "The public IP address of the deployed instance"
  value       = module.hopr-node-bootstrap-002.ipv4
}