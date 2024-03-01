#!/bin/bash

# Optionally load variables from .env file
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

# Set your project ID and zone here or load from environment
PROJECT_ID=${PROJECT_ID}
ZONE=${ZONE}

# Delete VMs asynchronously without looping
gcloud compute instances delete cp1-lfclass \
  --project=${PROJECT_ID} \
  --zone=${ZONE} \
  --quiet &

gcloud compute instances delete worker1-lfclass \
  --project=${PROJECT_ID} \
  --zone=${ZONE} \
  --quiet 
# Wait for the background job to finish
wait

echo "All instances deleted."

