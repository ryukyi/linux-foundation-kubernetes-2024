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
SERVICE_ACCOUNT=${SERVICE_ACCOUNT}
NETWORK_NAME=${NETWORK_NAME}
FIREWALL_RULE_NAME_ALLOW_ALL=${FIREWALL_RULE_NAME_ALLOW_ALL}
FIREWALL_RULE_NAME_SSH=${FIREWALL_RULE_NAME_SSH}
ZONE=${ZONE}
# SSH key need to handle whitespace
# e.g. ssh-ed25519\ 1lZDI1NTEuqhbW5mymC7R\ username@gmail.com
SSH_KEYS=${SSH_KEYS}
# email name e.g username
GCP_NAME=${GCP_NAME}

# Non secret environment variables
MACHINE_TYPE=n2-standard-4
IMAGE=projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20240319
DISK_TYPE=projects/${PROJECT_ID}/zones/${ZONE}/diskTypes/pd-balanced

# Create VPC network
gcloud compute networks create ${NETWORK_NAME} \
  --project=${PROJECT_ID} \
  --description="VPC Network for kubernetes class" \
  --subnet-mode=auto \
  --mtu=1460 \
  --bgp-routing-mode=regional

# Allow all on the network
gcloud compute firewall-rules create lfk-vpc-firewall-all \
  --project=${PROJECT_ID} \
  --description="Firewall rule for all traffic" \
  --direction=INGRESS \
  --priority=1000 \
  --network=${NETWORK_NAME} \
  --action=ALLOW \
  --rules=all \
  --source-ranges=0.0.0.0/0 

# Create cp1-lfclass control plane node
VM_NAME=cp1-lfclass
gcloud compute instances create ${VM_NAME} \
	--project=${PROJECT_ID} \
	--zone=${ZONE} \
	--machine-type=${MACHINE_TYPE} \
	--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=${NETWORK_NAME} \
	--maintenance-policy=MIGRATE \
	--provisioning-model=STANDARD \
	--service-account=${SERVICE_ACCOUNT} \
	--scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
	--tags=http-server,https-server \
	--create-disk=auto-delete=yes,boot=yes,device-name=${VM_NAME},image=${IMAGE},mode=rw,size=20,type=${DISK_TYPE} \
	--no-shielded-secure-boot \
	--shielded-vtpm \
	--shielded-integrity-monitoring \
	--labels=goog-ec-src=vm_add-gcloud \
	--reservation-affinity=any

# enable ssh
gcloud compute instances add-metadata ${VM_NAME} --zone=${ZONE} --metadata "ssh-keys=${GCP_NAME}:${SSH_KEYS}"

# Create worker1-lfclass node
VM_NAME=worker1-lfclass
gcloud compute instances create ${VM_NAME} \
	--project=${PROJECT_ID} \
	--zone=${ZONE} \
	--machine-type=${MACHINE_TYPE} \
	--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=${NETWORK_NAME} \
	--maintenance-policy=MIGRATE \
	--provisioning-model=STANDARD \
	--service-account=${SERVICE_ACCOUNT} \
	--scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
	--tags=http-server,https-server \
	--create-disk=auto-delete=yes,boot=yes,device-name=${VM_NAME},image=${IMAGE},mode=rw,size=20,type=${DISK_TYPE} \
	--no-shielded-secure-boot \
	--shielded-vtpm \
	--shielded-integrity-monitoring \
	--labels=goog-ec-src=vm_add-gcloud \
	--reservation-affinity=any

# enable ssh
gcloud compute instances add-metadata ${VM_NAME} --zone=${ZONE} --metadata "ssh-keys=${GCP_NAME}:${SSH_KEYS}"
# setup base image with deps

# Setup nodes
# control plane scripts
gcloud compute scp \
	03_install/cilium-cni.yaml \
	03_install/kube-config-setup-control-plane.sh \
	03_install/kubeadm-config.yaml \
	cp1-lfclass:/tmp --zone "${ZONE}"
gcloud compute ssh cp1-lfclass --project "${PROJECT_ID}" --zone "${ZONE}" --command "bash -s" < "./03_install/setup-base.sh"

# worker
gcloud compute ssh worker1-lfclass --project "${PROJECT_ID}" --zone "${ZONE}" --command "bash -s" < "./03_install/setup-base.sh"
