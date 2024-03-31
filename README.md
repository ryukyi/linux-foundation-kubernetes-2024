# lfk-2024 - GCP Resource Management Scripts
Google Cloud Platform (GCP) scripts and tutorials for 
[Linux Foundation - Kubernetes Fundamentals LFS258](https://trainingportal.linuxfoundation.org/courses/kubernetes-fundamentals-lfs258)

## Prerequisites

- Ensure you have the [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and configured.
- Google cloud account with funds
- Make sure you have the necessary permissions to create and delete resources in the GCP project.

- MAKE SURE TO DELETE WHEN NOT USING 🤑

## Usage

Set up environment variables in a `.env` file or export them directly in your shell session. Alternative declare them in the shell as env vars

### Environment Variables
The required variables are:

- `SERVICE_ACCOUNT`: Service account email associated with the instances.
- `PROJECT_ID`: Your GCP project ID.
- `NETWORK_NAME`: Name of the VPC network to create.
- `FIREWALL_RULE_NAME_ALLOW_ALL`: Name of the firewall rule to allow all traffic.
- `FIREWALL_RULE_NAME_SSH`: Name of the firewall rule to allow SSH traffic.
- `ZONE`: Zone where the instances will be created.
- `SSH_KEYS`: SSH public keys for the instances.
- `GCP_NAME`: Your GCP account name.

For example, your `.env` file might look like this:

```bash
SERVICE_ACCOUNT=my-service-account@my-gcp-project.iam.gserviceaccount.com 
PROJECT_ID=my-gcp-project 
NETWORK_NAME=my-vpc-network 
FIREWALL_RULE_NAME_ALLOW_ALL=allow-all-traffic 
FIREWALL_RULE_NAME_SSH=allow-ssh-traffic 
ZONE=us-central1-a 
SSH_KEYS=ssh-rsaed123\ AAAABCDEFGHijklmnopqrstuvwXYZ\ usernamebeforeemail@gmail.com
GCP_NAME=usernamebeforeemail
```

### Creating VPC Rules, Firewall and Instances

Run bash script:

```bash
./gcp_create_vpc_rules_control_plane_and_worker.sh
```

### Deleting All Resources in Project

Run bash script:

```bash
./gcp_delete_all_resources_in_project.sh
```

### Helpful gcloud commands to get up and running

#### List vm instance names and external IP

```bash
gcloud compute instances list --project=lfk-kubernetes --zones=us-east --format="table(name,networkInterfaces[0].accessConfigs[0].natIP)"
# eg output
# NAME             NETWORK_IP
# cp1-lfclass      34.87.202.144
# worker1-lfclass  35.244.126.150
```
#### ssh into vm

```bash
ssh -i ~/.ssh/path_to_private_key host@externalIP 
# e.g. ssh -i ~/.ssh/work_dell_debian ryukyi@34.29.157.49
```