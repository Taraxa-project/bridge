#!/bin/bash

# Path to the DEPLOY.md file
DEPLOY_MD="./DEPLOY.md"
# Header for the deployment section
echo "## Deployment Details" >> "$DEPLOY_MD"
echo "" >> "$DEPLOY_MD"
# Loop through all JSON files in the deployments directory
files=$(find ./deployments -type f -name '*.json')
for file in $files; do
    echo "Reading $file..."
    # Extract deployment data using jq
    deployment_data=$(jq '.' "$file")
    # Append the data to the DEPLOY.md file
    echo "### Deployment from $file" >> "$DEPLOY_MD"
    echo '```json' >> "$DEPLOY_MD"
    echo "$deployment_data" >> "$DEPLOY_MD"
    echo '```' >> "$DEPLOY_MD"
    echo "" >> "$DEPLOY_MD"
done
echo "Deployment data appended to DEPLOY.md"