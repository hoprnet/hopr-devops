# hopr-devops
![Terraform](https://github.com/hoprnet/hopr-devops/workflows/Terraform/badge.svg)

HOPR regional and zones configuration data used to deploy nodes in different environments

# Usage

HOPR Services AG datacenter infrastructure is managed an automated via this repository. Executing changes and pushing these against `master` will automatically trigger our GitHub action under [./.github/workflows/terraform.yml](./.github/workflows/terraform.yml), which connects to our GCP account and deploys our [HOPR Chat Terraform Module](./modules/services/hopr) on them. Depending on the parameters given, it can deploy nodes in **bootstrap** or **core** mode.

## Creating a new Datacenter

Datacenters are composed by two important settings:

- Country
- Environment

Each Datacenter needs to have these configurations defined in the form of a Google Cloud Platform (GCP) Project. In other words, each Datacenter represents an isolated project inside GCP that has its own permissions, machines and access to control with.

To create a Datacenter, you first need to create a new Project and stablish the region (country) alongside the environment the Datacenter will represent. At the time of writing, the following are acceptable environments:

- `develop`
- `testing`
- `staging`
- `production`

The following script will create a `develop` datacenter scoped to be in the `nl` region.

```bash
gcloud projects create hopr-nl-develop --folder=$FOLDER_ID --organization=$ORGANIZATION_ID
```

## Deploying a new HOPR Chat release to a Datacenter

### Building a Docker image using Google Cloud Build

For the time being, the first step of creating a new release to our Datacenter is to manually create a HOPR Chat release. This will be automated in the following [issue](https://github.com/hoprnet/hopr-devops/issues/16).

To do so, ensure you are logged in with a Google Account able to use Google Cloud Build or your own personal account for HOPR Association. All images for HOPR Chat are built under the `hoprassociation` project.

Run the following command inside `hopr-core/chat`

`gcloud builds submit --tag gcr.io/hoprassociation/hopr-core:testnet-$(git rev-parse --short HEAD)`

> Right now `hopr-core` represents HOPR Chat internally in our images, but inside our Docker Hub registry this is accurately represented with a `hopr/chat` image.

After successfully building the image, the command will produce an output similar to the following:

```bash
--------------------------------------------------------------------------------------------------------------------

ID                                    CREATE_TIME                DURATION  SOURCE                                                                                     IMAGES                                            STATUS
90e9353e-96b7-441e-8a03-d50bbca00f2e  2020-06-24T08:05:44+00:00  5M11S     gs://hoprassociation_cloudbuild/source/1592985942.88-0b8507251d634ae6af57f86e4cf9f372.tgz  gcr.io/hoprassociation/hopr-core:testnet-52d6767  SUCCESS
```

Grab the image described as `gcr.io/hoprassociation/*` for later. We'll refer to this image as $DOCKER_IMAGE within our documentation for further references.

### Update nodes per Datacenter

The following actions are needed to be repeated per Datacenter. In this case, we'll document the datacenter as `$DATACENTER`, where `$DATACENTER.country` and `$DATACENTER.environment` will be used to represent the Datacenter's country and environment within our code.

#### Update bootstrap server inside $DATACENTER

Go to hopr-devops and change `$DATACENTER.country/$DATACENTER.environment/services/hopr-bootstrap/main.tf` with the new `$DOCKER_IMAGE` in the `container_image` value. Commit these changes to `master` and push them to GitHub. This will trigger the [Terraform GitHub Workflow](https://github.com/hoprnet/hopr-devops/actions?query=workflow%3ATerraform) that will automatically reapply and rebuild our Bootstrap nodes.

#### Obtain the new $DATACENTER_BOOTSTRAP_SERVER

Upon deployment, go to `$DATACENTER.country/$DATACENTER.environment/services/hopr-bootstrap` and run the command the following command (described in our Cookbook described as “Seeing the latest logs from all machines”). Ensure your `GOOGLE_APPLICATION_CREDENTIALS` account is setup to this Datacenter to be able to run the `terraform` part properly, as described under “Additional Notes”.

```
# Ensure you are in the correct directory
$ pwd
/Users/hopr/Projects/hopr/hopr-devops/ch/testing/services/hopr-bootstrap
$ GOOGLE_APPLICATION_CREDENTIALS=/Users/hopr/Downloads/hopr-ch-testing-ebaeafd82f0a.json
# Use the actual docker image generated previously.
$ DOCKER_IMAGE=gcr.io/hoprassociation/hopr-core:testnet-52d6767
$ terraform output -json instances | jq -r 'to_entries[] | .value' | xargs -n1 -I {} ssh daneel@{} "docker ps -q --filter \"ancestor=$DOCKER_IMAGE\" | xargs -I [] docker logs --tail 10 []"
```

You should see output from multiple machine as follows:
```
Available under the following addresses:
 /ip4/34.65.141.74/tcp/9091/p2p/16Uiu2HAmRD7iEEopoiHWz7NpsM4wwSc5yWpdSX3esb3kYkJNY1yn
 /ip4/127.0.0.1/tcp/9091/p2p/16Uiu2HAmRD7iEEopoiHWz7NpsM4wwSc5yWpdSX3esb3kYkJNY1yn
 /ip4/10.172.0.17/tcp/9091/p2p/16Uiu2HAmRD7iEEopoiHWz7NpsM4wwSc5yWpdSX3esb3kYkJNY1yn
 /ip4/172.17.0.1/tcp/9091/p2p/16Uiu2HAmRD7iEEopoiHWz7NpsM4wwSc5yWpdSX3esb3kYkJNY1yn
 /ip4/172.18.0.1/tcp/9091/p2p/16Uiu2HAmRD7iEEopoiHWz7NpsM4wwSc5yWpdSX3esb3kYkJNY1yn

... running as bootstrap node!.
```

Take a note of the ones with public IP and create an array with them. These are now your `$DATACENTER` bootstrap nodes. In this particular case, these ones are the following:

```
/ip4/34.65.111.179/tcp/9091/p2p/16Uiu2HAm5WUS1kv8p3uiSgZmz2uh427qr8jJZ8jrFCePHATaVgz2
/ip4/34.65.141.74/tcp/9091/p2p/16Uiu2HAmRD7iEEopoiHWz7NpsM4wwSc5yWpdSX3esb3kYkJNY1yn
```

> In case your datacenter is other than `develop`, you will need to update the entries of HOPR's DNS to match the new given IPs.

#### Update node server inside $DATACENTER

Go to hopr-devops and change `$DATACENTER.country/$DATACENTER.environment/services/hopr-node/main.tf` with the new `$DOCKER_IMAGE` in the `container_image` value **AND** with the new `$DATACENTER_BOOTSTRAP_SERVER` in the `bootstrap_servers` value under `locals`. Commit these changes to `master` and push them to GitHub. This will trigger the [Terraform GitHub Workflow](https://github.com/hoprnet/hopr-devops/actions?query=workflow%3ATerraform) that will automatically reapply and rebuild our HOPR Chat nodes.

#### Restart bootstrap servers inside $DATACENTER

As a precautionary measure, run the following command to restart the Bootstrap Servers inside your `$DATACENTER/services/hopr-bootstrap` folder to ensure the Bootstrap nodes are ready to be listened to. This command is also document in our Cookbook as “Restarting the docker container images”. Their Docker containers IDs will show up as the output of the command.

```
$ DOCKER_IMAGE=gcr.io/hoprassociation/hopr-core:testnet-52d6767
$ terraform output -json instances | jq -r 'to_entries[] | .value' | xargs -n1 -I {} ssh daneel@{} "docker ps -q --filter \"ancestor=$DOCKER_IMAGE\" | xargs -I [] docker restart []"
867a1f258cd3
e055aac96d3c
```

You can then retrieve the logs again to confirm the nodes were able to connect to the bootstrap server, as their HOPR Addresses will show up in the logs due them being in debug mode.

```
$ terraform output -json instances | jq -r 'to_entries[] | .value' | xargs -n1 -I {} ssh daneel@{} "docker ps -q --filter \"ancestor=$DOCKER_IMAGE\" | xargs -I [] docker logs --tail 10 []"
...
 /ip4/34.65.141.74/tcp/9091/p2p/16Uiu2HAmRD7iEEopoiHWz7NpsM4wwSc5yWpdSX3esb3kYkJNY1yn
 /ip4/127.0.0.1/tcp/9091/p2p/16Uiu2HAmRD7iEEopoiHWz7NpsM4wwSc5yWpdSX3esb3kYkJNY1yn
 /ip4/10.172.0.17/tcp/9091/p2p/16Uiu2HAmRD7iEEopoiHWz7NpsM4wwSc5yWpdSX3esb3kYkJNY1yn
 /ip4/172.17.0.1/tcp/9091/p2p/16Uiu2HAmRD7iEEopoiHWz7NpsM4wwSc5yWpdSX3esb3kYkJNY1yn
 /ip4/172.18.0.1/tcp/9091/p2p/16Uiu2HAmRD7iEEopoiHWz7NpsM4wwSc5yWpdSX3esb3kYkJNY1yn

... running as bootstrap node!.
Incoming connection from 16Uiu2HAmLTmPUBXABSuoVPqhXo5wCbvk1i4fxqUPGU8GbPd61LFG.
Incoming connection from 16Uiu2HAm9417JBwbF1TaaEQVLYpECAqr7H6BP9BuKt6fG6VLA5JQ.
Incoming connection from 16Uiu2HAm44U6Ea7JPBuNG2kDzNJdLgaDj5AkgDpRaYc5ghLeUo4v.
```

After ensuring the connection is incoming, you can then locally connect to it using the Docker image yourself and/or running one of our binaries under `hopr-core` [releases page](https://github.com/hoprnet/hopr-core/releases).

Congratulations! You've deployed `$DATACENTER` with a new HOPR Chat instance.

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

## Additional Notes

- Moving between environments is currently mapped as different projects. You will need change the credentials used for `Terraform` locally everytime you want to inspect a different datacenter.

- Updating the environment variables do not recreate the machine. You need to change the container image as to recreate the virtual machine used for the specific container to recreate also the container with the new variables.

- Sometimes the machines fail to connect to bootstrap servers after some idle time. Restarting both bootstrap servers and machines will help them connect.

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

- [ ] Add instructions on how to create service account and buckets for a new Datacenter.
- [ ] [Automate the creation of Docker images to ensure anyone can create an official HOPR Chat image](https://github.com/hoprnet/hopr-devops/issues/16)
- [ ] Provide a better command to parse the outputs of the bootstrap nodes to obtain only the first line to avoid having to copy the correct entry manually.
- [ ] Add a persistent disk to the module to ensure that upon destruction of a VM the IP does not change and the DNS update isn't needed.
- [ ] Automate the creation of projects, buckets and service accounts for deploying Datacenters and Services.
- [ ] Create a version setup linked to branches (e.g. `master` deploys to production).

