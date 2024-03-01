#!/bin/bash

# Optionally load variables from .env file or set them here
# PROJECT_ID=<your-project-id>
# NETWORK_NAME=<your-network-name>
# FIREWALL_RULE_NAME_ALLOW_ALL=<your-firewall-rule-name>
while IFS='=' read -r key value
do
  # Trim leading and trailing whitespace from key and value
  key=$(echo $key | xargs)
  value=$(echo $value | xargs)

  # Skip empty lines and lines without an assignment
  [[ -z "$key" || -z "$value" ]] && continue

  # Export the environment variable, using eval to handle complex cases safely
  if [[ "$key" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]]; then
    eval export $key=\"$value\"
  else
    echo "Skipping invalid variable name: $key"
  fi
done < .env

# Secret environment variables
PROJECT_ID=${PROJECT_ID}
# NOTE: ssh keys var is of the form: 
# ssh-keys=googleusername:ssh-ed25519\ AAAAC3Nz...
SERVICE_ACCOUNT=${SERVICE_ACCOUNT}
SSH_KEYS=${SSH_KEYS}
NETWORK_NAME=${NETWORK_NAME}
FIREWALL_RULE_NAME_ALLOW_ALL=${FIREWALL_RULE_NAME_ALLOW_ALL}
FIREWALL_RULE_NAME_SSH=${FIREWALL_RULE_NAME_SSH}
ZONE=${ZONE}
GCP_NAME=${GCP_NAME}

# Non secret environment variables
MACHINE_TYPE=n2-standard-4
IMAGE=projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20240227
DISK_TYPE=projects/${PROJECT_ID}/zones/${ZONE}/diskTypes/pd-balanced

# Create VPC network
gcloud compute networks create ${NETWORK_NAME} \
  --project=${PROJECT_ID} \
  --description="VPC Network for kubernetes class" \
  --subnet-mode=auto \
  --mtu=1460 \
  --bgp-routing-mode=regional

# Allow all on the network
gcloud compute firewall-rules create ${FIREWALL_RULE_NAME_ALLOW_ALL} \
  --project=${PROJECT_ID} \
  --description="Firewall rule for all traffic" \
  --direction=INGRESS \
  --priority=1000 \
  --network=${NETWORK_NAME} \
  --action=ALLOW \
  --rules=all \
  --source-ranges=0.0.0.0/0 

# NOTE: ssh keys var is of the form: 
# ssh-keys=googleusername:ssh-ed25519\ AAAAC3Nz...

# Create command for cp1-lfclass
VM_NAME=cp1-lfclass
gcloud compute instances create ${VM_NAME} \
  --project=${PROJECT_ID} \
  --zone=${ZONE} \
  --machine-type=${MACHINE_TYPE} \
  --network-interface=network-tier=STANDARD,stack-type=IPV4_ONLY,subnet=${NETWORK_NAME} \
  --metadata="${SSH_KEYS}" \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --service-account=${SERVICE_ACCOUNT} \
  --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
  --create-disk=auto-delete=yes,boot=yes,device-name=${VM_NAME},image=${IMAGE},mode=rw,size=20,type=${DISK_TYPE} \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any

# Add GCP node IP to host for control plane
ip_address=$(gcloud compute instances describe "$VM_NAME" --project "$PROJECT_ID" --zone "$ZONE" --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
# sometimes GCP reuse IP addresses for a user
ssh-keygen -f $HOME/.ssh/known_hosts -R $ip_address
# Install config defaults
scp -i ~/.ssh/$GCP_NAME -r 03_install/** $GCP_NAME@$ip_address:~
# Setup everything
gcloud compute ssh "$VM_NAME" --project "$PROJECT_ID" --zone "$ZONE" --command "bash -s ./setup-base.sh"
gcloud compute ssh "$VM_NAME" --project "$PROJECT_ID" --zone "$ZONE" --command "bash -s ./setup-control-plane.sh"



# Create command for worker1-lfclass
VM_NAME=worker1-lfclass
gcloud compute instances create ${VM_NAME} \
  --project=${PROJECT_ID} \
  --zone=${ZONE} \
  --machine-type=${MACHINE_TYPE} \
  --network-interface=network-tier=STANDARD,stack-type=IPV4_ONLY,subnet=${NETWORK_NAME} \
  --metadata="${SSH_KEYS}" \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --service-account=${SERVICE_ACCOUNT} \
  --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
  --create-disk=auto-delete=yes,boot=yes,device-name=${VM_NAME},image=${IMAGE},mode=rw,size=20,type=${DISK_TYPE} \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any

# Add GCP node IP to host for worker
ip_address=$(gcloud compute instances describe "$VM_NAME" --project "$PROJECT_ID" --zone "$ZONE" --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
# sometimes GCP reuse IP addresses for a user
ssh-keygen -f $HOME/.ssh/known_hosts -R $ip_address
# Setup everything
gcloud compute ssh "$VM_NAME" --project "$PROJECT_ID" --zone "$ZONE" --command "bash -s" < "./setup-base.sh"


