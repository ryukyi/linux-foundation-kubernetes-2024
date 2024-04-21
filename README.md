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

### Setting up worker

After creating vpc, firewall and control plane and worker above internal host names and certificates need to be updated.

First rename remote machines using your local ssh config:

```txt
Host worker1-lfclass
    HostName <XX.XXX.XX.XX>
    User <XXXXX>
    Port 22
    IdentityFile ~/.ssh/linxufoundation

Host cp1-lfclass
    HostName <XX.XXX.XX.XX>
    User <XXXXX>
    Port 22
    IdentityFile ~/.ssh/linxufoundation
```

#### ssh into vm and reboot

Do this for all nodes for example control plane:

```bash
ssh cp1-lfclass
sudo reboot
ssh worker1-lfclass
sudo reboot
```

### run setup control plane script

ssh into the control plan cp1-lfclass

```bash
cp /tmp/*.{sh,yaml} $HOME/
chmod +x $HOME/kube-config-setup-control-plane.sh
$HOME/kube-config-setup-control-plane.sh
```

### manually setup worker

Add k8scp to local hosts in both control plane and workers

```bash
# find internal ipv4
hostname -i
```

output example updated `/etc/hosts`
```txt
127.0.0.1 localhost
10.128.0.4 k8scp # <- add this line
```

ssh into worker and join the node for example using the copied tokens from cp1-lfclass:

```bash
kubeadm join \
    --token 27eee4.6e66ff60318da929 \
    k8scp:6443 \
    --discovery-token-ca-cert-hash \
    sha256:6d541678b05652e1fa5d43908e75e67376e994c3483d6683f2a18673e5d2a1b0
```

The tokens are created at the end of the script: [kube-config-setup-control-plane.sh](/03_install/kube-config-setup-control-plane.sh)
