#!/bin/bash

echo "#################################"
echo "#                               #"
echo "#          RUN THIS             #"
echo "#    AFTER ETH DEPLOYMENT       #"
echo "#                               #"
echo "#################################"


source .env

echo "RPC: $RPC_FICUS_PRNET"
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
res=$(forge script src/scripts/Tara.deploy.s.sol:TaraDeployer --via-ir --rpc-url $RPC_FICUS_PRNET --broadcast --legacy)

echo "$res"  >> deployment-tara.log

if [ $? -ne 0 ]; then
  echo "Error running deployment script for TaraClient"
  exit 1
fi



# TBD: leaving this for future implementation or reference
# echo "Getting Storage proof for the last finalized ETH bridge root epoch"

# proof=$(curl --request POST \
#   --url https://holesky.drpc.org \
#   --header 'accept: application/json' \
#   --header 'content-type: application/json' \
#   --data '{
#   "id": 1,
#   "jsonrpc": "2.0",
#   "method": "eth_getProof",
#   "params": [
#     "0xFF77e5c4C3f91A7d8014a34593c11A6bFC348805", ["0x0000000000000000000000000000000000000000000000000000000000000006"],"latest"
#   ]}' | jq .result.storageHash)

# echo "Storage proof: $proof"

# # Write storage proof to .env var

# echo "STORAGE_PROOF=$proof" >> .env

