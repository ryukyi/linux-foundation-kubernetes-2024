#!/bin/bash

# Load variables from .env file or set them here
while IFS='=' read -r key value; do
  key=$(echo $key | xargs)
  value=$(echo $value | xargs)
  [[ -z "$key" || -z "$value" ]] && continue
  if [[ "$key" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]]; then
    eval export $key=\"$value\"
  else
    echo "Skipping invalid variable name: $key"
  fi
done < .env

# Set the project
gcloud config set project $PROJECT_ID

# Function to delete Compute Engine instances
delete_instances() {
  echo "Deleting Compute Engine instances..."
  gcloud compute instances list --format="value(name,zone)" --project=$PROJECT_ID | while read -r INSTANCE_NAME ZONE; do
    gcloud compute instances delete "$INSTANCE_NAME" --zone="$ZONE" --quiet 
  done
}

# Function to delete Cloud Storage buckets
delete_buckets() {
  echo "Deleting Cloud Storage buckets..."
  gsutil ls -p $PROJECT_ID | while read -r BUCKET; do
    gsutil -m rm -r "$BUCKET" &
  done
}

# Function to delete firewall rules
delete_firewall_rules() {
  if [[ -n "$NETWORK_NAME" ]]; then
    echo "Deleting firewall rules for network $NETWORK_NAME..."
    gcloud compute firewall-rules list --filter="network:$NETWORK_NAME" --format="value(name)" --project=$PROJECT_ID | while read -r RULE_NAME; do
      gcloud compute firewall-rules delete "$RULE_NAME" --quiet &
    done
  fi
}

# Function to delete subnetworks
delete_subnetworks() {
  echo "Deleting subnetworks..."
  # Assuming REGION is set or you want to delete subnetworks in all regions
  if [[ -n "$REGION" ]]; then
    gcloud compute networks subnets list --filter="region:($REGION)" --format="value(name,region)" --project=$PROJECT_ID | while read -r SUBNET_NAME SUBNET_REGION; do
      gcloud compute networks subnets delete "$SUBNET_NAME" --region="$SUBNET_REGION" --quiet &
    done
  else
    echo "REGION variable not set. Skipping subnetworks deletion."
  fi
}

# Function to delete VPC networks
delete_networks() {
  echo "Deleting VPC networks..."
  gcloud compute networks list --format="value(name)" --project=$PROJECT_ID | while read -r NETWORK_NAME; do
    gcloud compute networks delete "$NETWORK_NAME" --quiet 
  done
}

# Call functions
delete_instances
delete_buckets
delete_firewall_rules
delete_networks

# Wait for all background jobs to finish
wait

echo "All specified resources deleted."
