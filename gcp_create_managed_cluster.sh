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

# gcloud beta container \
#     --project "${PROJECT_ID}" clusters create "linuxfoundation" \
#     --no-enable-basic-auth \
#     --cluster-version "1.29.1-gke.1589017" \
#     --release-channel "rapid" \
#     --machine-type "n2-standard-2" \
#     --image-type "COS_CONTAINERD" \
#     --disk-type "pd-balanced" \
#     --disk-size "100" \
#     --metadata disable-legacy-endpoints=true \
#     --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
#     --num-nodes "3" \
#     --logging=SYSTEM,WORKLOAD \
#     --monitoring=SYSTEM \
#     --enable-ip-alias \
#     --network "projects/${PROJECT_ID}/global/networks/${NETWORK_NAME}" \
#     --subnetwork "projects/${PROJECT_ID}/regions/${ZONE_SUFFIX}/subnetworks/${NETWORK_NAME}" \
#     --no-enable-intra-node-visibility \
#     --default-max-pods-per-node "110" \
#     --security-posture=standard \
#     --workload-vulnerability-scanning=disabled \
#     --no-enable-master-authorized-networks \
#     --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
#     --enable-autoupgrade \
#     --enable-autorepair \
#     --max-surge-upgrade 1 \
#     --max-unavailable-upgrade 0 \
#     --binauthz-evaluation-mode=DISABLED \
#     --enable-managed-prometheus \
#     --enable-shielded-nodes \
#     --fleet-project=lfk-kubernetes \
#     --zone "${ZONE_SUFFIX}-a" \
#     --node-locations "${ZONE_SUFFIX}-a","${ZONE_SUFFIX}-b","${ZONE_SUFFIX}-c"
# ${NETWORK_NAME}

gcloud beta container \
    --project "${PROJECT_ID}" clusters create-auto "${CLUSTER_NAME}" \
    --region "${ZONE_SUFFIX}" \
    --release-channel "regular" \
    --network "projects/${PROJECT_ID}/global/networks/${NETWORK_NAME}" \
    --subnetwork "projects/${PROJECT_ID}/regions/${ZONE_SUFFIX}/subnetworks/${NETWORK_NAME}" \
    --cluster-ipv4-cidr "/17" \
    --binauthz-evaluation-mode=DISABLED
