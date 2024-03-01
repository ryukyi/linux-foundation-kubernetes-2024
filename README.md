# lfk-2024 - GCP Resource Management Scripts

[Linux Foundation - Kubernetes Fundamentals LFS258](https://trainingportal.linuxfoundation.org/courses/kubernetes-fundamentals-lfs258)

## Overview

This repository contains scripts for managing resources in a Google Cloud Platform (GCP) project.

## Prerequisites

- Ensure you have the [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and configured.
- Google cloud account with funds
- Make sure you have the necessary permissions to create and delete resources in the GCP project.

## Usage

Set up environment variables in a `.env` file or export them directly in your shell session. Alternative declare them in the shell as env vars

### Environment Variables
The required variables are:

- `PROJECT_ID`: Your GCP project ID.
- `NETWORK_NAME`: Name of the VPC network to create.
- `FIREWALL_RULE_NAME_ALLOW_ALL`: Name of the firewall rule to allow all traffic.
- `FIREWALL_RULE_NAME_SSH`: Name of the firewall rule to allow SSH traffic.
- `ZONE`: Zone where the instances will be created.
- `SERVICE_ACCOUNT`: Service account email associated with the instances.
- `SSH_KEYS`: SSH public keys for the instances.

For example, your `.env` file might look like this:

```bash
SERVICE_ACCOUNT=my-service-account@my-gcp-project.iam.gserviceaccount.com SSH_KEYS=ssh-keys=myuser:ssh-rsa AAAAB...
PROJECT_ID=my-gcp-project 
NETWORK_NAME=my-vpc-network 
FIREWALL_RULE_NAME_ALLOW_ALL=allow-all-traffic 
FIREWALL_RULE_NAME_SSH=allow-ssh-traffic 
ZONE=us-central1-a 
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

### Deleting Specific VM Instances

```bash
./gcp_delete_vm_instances.sh
```