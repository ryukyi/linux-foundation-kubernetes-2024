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
NETWORK_NAME=${NETWORK_NAME}
ZONE_SUFFIX=${ZONE_SUFFIX}
CLUSTER_NAME=${CLUSTER_NAME}

gcloud beta container \
    --project "${PROJECT_ID}" clusters delete "${CLUSTER_NAME}" \
    --zone "${ZONE_SUFFIX}"