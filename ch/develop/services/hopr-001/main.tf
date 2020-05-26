terraform {
  backend "gcs" {
    bucket = "hopr-ch-develop-terraform-state"
    prefix = "terraform/state"
  }
}

provider google {
  project = "hopr-ch-develop"
  region  = "europe-west6"
  version = "~> 3.0"
}

module "hopr-node" {
  source                = "../../../../modules/services/hopr"
  name                  = "hopr-ch-develop-container"
  instance_name         = "hopr-ch-develop-001"
  project_id            = "hopr-ch-develop"
  region                = "europe-west6"
  zone                  = "europe-west6-a"
  image_port            = "9091"
  client_email          = "terraform@hopr-ch-develop.iam.gserviceaccount.com"
  container_image       = "gcr.io/hoprassociation/hopr-core:latest"
  env_ETHEREUM_PROVIDER = "wss://kovan.infura.io/ws/v3/f7240372c1b442a6885ce9bb825ebc36"
  env_HOST_IPV4         = "0.0.0.0:9091"
  env_BOOTSTRAP_SERVERS = "/dns4/bootstrap01.hoprnet.io/tcp/9091/p2p/16Uiu2HAm3mkxuhtz2q8aFdNtUXkpp7T3Pqk6pZThtYEnVYetPhyo"
  container_arguments   = ["-p", "123456"]
  key                   = "key.pub"
}

output "ipv4" {
  description = "The public IP address of the deployed instance"
  value       = module.hopr-node.ipv4
}