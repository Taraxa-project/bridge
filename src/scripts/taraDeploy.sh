#!/bin/bash

echo "#################################"
echo "#                               #"
echo "#          RUN THIS             #"
echo "#       AFTER ETH DEPLOYMENT    #"
echo "#################################"


source .env

echo "RPC: $RPC_FICUS_PRNET"
echo "PRIVATE_KEY: $PRIVATE_KEY"
# Check if the RPC_URL and PRIVATE_KEY are set
if [ -z "$RPC_FICUS_PRNET" ] || [ -z "$PRIVATE_KEY" ]; then
  echo "Please set the RPC_FICUS_PRNET and PRIVATE_KEY in the .env file"
  exit 1
fi

echo "Calculating current sync committe aggregated PK"

pk=$(python3 src/scripts/calculate_sync_committee_hash.py)

if [ $? -ne 0 ]; then
  echo "Error calculating current sync committe aggregated PK"
  exit 1
fi

echo "Deploying BeaconLightClient contract"

# Run the deployment script for TaraClient
res=$(forge script src/scripts/Tara.deploy.s.sol:TaraDeployer --via-ir --rpc-url $RPC_FICUS_PRNET --broadcast | jq)

if [ $? -ne 0 ]; then
  echo "Error running deployment script for TaraClient"
  exit 1
fi

echo "$res" >> deployment-eth.json