# hopr-devops
![Terraform](https://github.com/hoprnet/hopr-devops/workflows/Terraform/badge.svg)

HOPR regional and zones configuration data used to deploy nodes in different environments

# Usage

HOPR Services AG datacenter infrastructure is managed an automated via this repository. Executing changes and pushing these against `master` will automatically trigger our GitHub action under [./.github/workflows/terraform.yml](./.github/workflows/terraform.yml), which connects to our GCP account and deploys our [HOPR Chat Terraform Module](./modules/services/hopr) on them. Depending on the parameters given, it can deploy nodes in **bootstrap** or **core** mode.


# Development

## Setup

To develop locally on this repository, please make sure you have the following installed in your workstation:

- [Terraform 13.x Beta](https://github.com/hashicorp/terraform/issues/25016)
- [GCloud](https://cloud.google.com/sdk/install)
- [jq](https://stedolan.github.io/jq/download/)

_jq is not needed to develop on this repository, but will make handling the output of Terraform easier_

### Service Accounts

You will need to have at least an active Service Account with the following roles enabled:

- Storage Admin
- Storage Object Viewer
- *Owner

_*Project Owner can be modified for Compute Engine Admin, Logging.logEntries.create, and Monitoring.timeSeries.create*_

### Exporting Service Account to Terraform

Afterwards, ensure you point Terraform about the location of your Service Account. One way to do so goes as follows:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/Users/hopr/Downloads/service_account_json_file.json
```

### Initializing Terraform

After providing the service account to Terraform, ensure you initialize it in the service you want to use it. This will sync your workstation with the latest state stored in the GCS bucket.

```bash
➜  hopr-bootstrap git:(master) ✗ pwd
/Users/hopr/Projects/hopr/hopr-devops/ch/develop/services/hopr-bootstrap
➜  hopr-node git:(master) terraform init
Initializing modules...

Initializing the backend...

Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Finding hashicorp/google versions matching "~> 3.0"...
- Installing hashicorp/google v3.26.0...
- Installed hashicorp/google v3.26.0 (signed by HashiCorp)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```


### Testing Account
To test everything is working, you can navegate to any service within a specific environment and run the following command.

```bash
➜  hopr-bootstrap git:(master) ✗ terraform output -json instances | jq
{
  "ch-develop-hopr-bootstrap-ae7df441-1": "34.65.237.196",
  "ch-develop-hopr-bootstrap-ae7df441-2": "34.65.69.76",
  "ch-develop-hopr-bootstrap-ae7df441-3": "34.65.75.45"
}
```

## Accessing Servers
If you have access to the `SSH_PUB_KEY` used to deploy the datacenter, you can SSH into these machines. Otherwise you can always use `gcloud compute ssh $MACHINE`. Both options require you to have access to the specific HOPR project.

#### Using SSH_PUB_KEY
```bash
➜  hopr-bootstrap git:(master) ✗ terraform output -json instances | jq -r 'to_entries[] | .value' | head -n 1
34.65.237.196
➜  hopr-bootstrap git:(master) ✗ ssh -i ~/.ssh/daneel_ed25519 daneel@$(!!)
➜  hopr-bootstrap git:(master) ✗ ssh -i ~/.ssh/daneel_ed25519 daneel@$(terraform output -json instances | jq -r 'to_entries[] | .value' | head -n 1)
The authenticity of host '34.65.237.196 (34.65.237.196)' can't be established.
ED25519 key fingerprint is SHA256:M2jl0YECDAB0j5PH8X6WkDFQYpMBspT1MgwFAO2CdkI.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '34.65.237.196' (ED25519) to the list of known hosts.
  ########################[ Welcome ]########################
  #  You have logged in to the guest OS.                    #
  #  To access your containers use 'docker attach' command  #
  ###########################################################

daneel@ch-develop-hopr-bootstrap-ae7df441-1 ~ $
```

#### Using gcloud
```bash
➜  hopr-bootstrap git:(master) ✗ terraform output -json instances | jq -r 'to_entries[] | .value' | head -n 1
➜  hopr-bootstrap git:(master) ✗ gcloud compute ssh $(!!)
➜  hopr-bootstrap git:(master) ✗ gcloud compute ssh $(terraform output -json instances | jq -r 'to_entries[] | .key' | head -n 1)
No zone specified. Using zone [europe-west6-a] for instance: [ch-develop-hopr-bootstrap-ae7df441-1].
Updating project ssh metadata...⠹Updated [https://www.googleapis.com/compute/v1/projects/hopr-ch-develop].
Updating project ssh metadata...done.
Waiting for SSH key to propagate.
Warning: Permanently added 'compute.7944747553294501796' (ED25519) to the list of known hosts.
Enter passphrase for key '/Users/hopr/.ssh/google_compute_engine':
Enter passphrase for key '/Users/hopr/.ssh/google_compute_engine':
  ########################[ Welcome ]########################
  #  You have logged in to the guest OS.                    #
  #  To access your containers use 'docker attach' command  #
  ###########################################################

hopr@ch-develop-hopr-bootstrap-ae7df441-1 ~ $
```

# Cookbook

#### Seeing the latest logs from all machines

```bash
terraform output -json instances | jq -r 'to_entries[] | .value' | xargs -n1 -I {} ssh daneel@{} "docker ps -q --filter \"ancestor=hopr/chat\" | xargs -I [] docker logs --tail 10 []"
```

#### Restarting the docker container images
```bash
terraform output -json instances | jq -r 'to_entries[] | .value' | xargs -n1 -I {} ssh daneel@{} "docker ps -q --filter \"ancestor=hopr/chat\" | xargs -I [] docker restart []"
```

#### SSH into a particular machine
```bash
ssh -i ~/.ssh/daneel_ed25519 daneel@$(terraform output -json instances | jq -r 'to_entries[] | .value' | head -n 1 | tail -n 1)
```


# Roadmap

- [ ] Automate the creation of projects, buckets and service accounts for deploying Datacenters and Services.
- [ ] Create a version setup linked to branches (e.g. `master` deploys to production).

