# Adhoc Deployments

Whenever we are unable to automate a deployment workflow, we create some commands for our deploying infrastructure “ad-hoc”, i.e. manually as it is needed. However, as to avoid having this infrastructure unmanaged and/or w/o visibility of our automated infrastructure, we have some particular requirements needed to be followed in order to have some sense of order.

The purpose of this documentation is to record the commands that are run as they are, and describe the rules needed for them to work.

## Requirements

### Software

To run our ad-hoc deployments, you need to have:

- `gcloud`
- Enabled `google cloud enable os login`
- Authenticated via `google auth init`
- Have access to our `ROOT` project as an `Editor`.

### Deployments Rules

1. All deployments are done against a particular image. All images are under `gcr.io/hoprassocation` and should be public.
2. All deployments are configurable via environment variables. **DO NOT STORE SECRETS IN THE IMAGE DURING BUILD TIME**.
3. All deployments are named as `project-environment-service-instance`. E.g. `libp2p-ipfs-demo-001`. `instance` and `environment` can be omitted if there's only going to be one.

### Deployment Types

There are two-types of adhoc deployments:

- OS-based deployment (e.g. `ubuntu` machine)
- Container deployment (e.g. `hopr/chat`)

Only use OS-based deployment if your application requires multiple services running within a machine and you are testing a project. Ideally, setup your project as to favour container-based deployment.

### Firewall Rules

All deployments need to use `tags` to target the specific firewall rules needed by the project. These can be created once and/or during deployment.

## Cookbook

Before executing your scripts, ensure you are in the right project:
```bash
gcloud config get-value project
```

**ONLY CREATE AD-HOC DEPLOYMENTS IN OUR ROOT PROJECT**

### OS-Base Deployment Script

#### General
```bash
gcloud compute instances create $project-$service --zone europe-west6-c
```

#### Specific Image
```bash
gcloud compute instances create $project-$service --zone europe-west6-c --image-family ubuntu-1804-lts --image-project gce-uefi-images
```

#### SSH into machine
```bash
gcloud compute ssh $project-service
```

#### Delete machine
```bash
gcloud compute instances delete $project-$service
```

### Container Based Deployment Script

#### General
```bash
gcloud compute instances create-with-container hopr-grpc-demo-003 \
  --zone=europe-west6-a --machine-type=f1-micro --subnet=default \
  --network-tier=PREMIUM --metadata=google-logging-enabled=true \
  --maintenance-policy=MIGRATE --tags=$TAGS \
  --boot-disk-size=10GB --boot-disk-type=pd-standard \
  --container-image=$DOCKER_IMAGE --container-restart-policy=always
```

#### Attached Disk and w/RW mount
```bash
gcloud compute instances create-with-container geth-full-node-001 \
  --zone europe-west4-a --tags geth-node \
  --create-disk name=geth-node,size=500GB,type=pd-ssd,device-name=geth-node,mode=rw 
  --container-image eu.gcr.io/hoprassociation/ethchain-geth 
  --container-command="/bin/sh" \
  --container-arg="-c" --container-arg="geth --datadir /root/.ethereum/ethchain-geth --rpc --rpcaddr 0.0.0.0 --rpccorsdomain \"*\" --rpcvhosts \"*\" \
  --ws --wsorigins \"*\" --wsaddr 0.0.0.0 --rpcapi eth,net,web3,txpool" \
  --container-mount-host-path mount-path=/root/.ethereum/ethchain-geth,host-path=/mnt/disks/gce-containers-mounts/gce-persistent-disks/geth-node,mode=rw
```

#### Additional Environment Variables
```bash
gcloud compute instances create-with-container mazebot-testnet-grpc-001 \
  --zone=europe-west6-a --machine-type=f1-micro --subnet=default --network-tier=PREMIUM \
  --metadata=google-logging-enabled=true --maintenance-policy=MIGRATE \
  --tags=grpc-server \
  --boot-disk-size=10GB --boot-disk-type=pd-standard --container-image=gcr.io/hoprassociation/hopr-server:latest \
  --container-env BOOTSTRAP_SERVERS="/ip4/34.65.82.167/tcp/9091/p2p/16Uiu2HAm6VH37RG1R4P8hGV1Px7MneMtNc6PNPewNxCsj1HsDLXW" \
  --container-restart-policy=always
```

## Deployments

### Mazebot (Testnet)

1. Deploy a **gRPC Server** with a **testnet bootstrap address** and `grpc-server` tag. You should get an IP like `34.*.*.*`
2. Test the server is alive by calling them via `BloomRPC` using `hoprnet/protos` `GetHoprAddress` on port `50051` to get their **HOPR Address**. It might need a bit of time to get the applications started. You can SSH into the machine to ensure the process is up and running.
3. Provide the IP and deploy the **envoy Server** with the `SERVICE_ADDRESS` as the **gRPC Server** as an env variable. You should also get an IP like `34.*.*.*`.
4. Deploy the **mazebot Client** and use `apiUrl=$ENVOY_SERVER` in the given IP listening to `3000` as part of the browser query URL.


## Preconfigured Server

### Envoy
```bash
gcloud compute instances create-with-container mazebot-testnet-proxy-001 \
  --zone=europe-west6-a --machine-type=f1-micro --subnet=default --network-tier=PREMIUM \
  --metadata=google-logging-enabled=true --maintenance-policy=MIGRATE \
  --tags=envoy-server \
  --boot-disk-size=10GB --boot-disk-type=pd-standard --container-image=gcr.io/hoprassociation/hopr-proxy/envoy-server:latest \
  --container-env SERVICE_ADDRESS="$GRPC_SERVER_IP" \
  --container-restart-policy=always
```

### Mazebot Client
```bash
gcloud compute instances create-with-container mazebot-testnet-client-001 \
  --zone=europe-west6-a --machine-type=f1-micro --subnet=default --network-tier=PREMIUM \
  --metadata=google-logging-enabled=true --maintenance-policy=MIGRATE \
  --tags=client-server \
  --boot-disk-size=10GB --boot-disk-type=pd-standard --container-image=gcr.io/hoprassociation/hopr-mazebot/client:latest \
  --container-restart-policy=always
```
