#!/bin/bash

echo "Starting the full deployment process..."

start_time=$(date +%s)

echo "Deploying tokens..."
make tokens-deploy

# Check if the deployment file was created
if [ ! -f .token.deployment.*.json ]; then
  echo "Error deploying tokens"
  exit 1
fi

echo "Deploying ETH components..."
make eth-deploy

# Check if the deployment file was created
if [ ! -f .eth.deployment.*.json ]; then
  echo "Error deploying ETH components"
  exit 1
fi

echo "Deploying TARA components..."
make tara-deploy

# Check if the deployment file was created
if [ ! -f .tara.deployment.*.json ]; then
  echo "Error deploying TARA components"
  exit 1
fi

echo "Deployment process completed."
formatted_date=$(date -r $start_time '+%Y-%m-%d %H:%M:%S')
deploymentMetadataFiles=$(find . -type f -name '*.json' -newermt "$formatted_date")

echo "Check the metadata files for the deployment details:"
echo "$deploymentMetadataFiles"

echo "Adding deployment metadata to DEPLOY.md..."

make add-deployment-metadata