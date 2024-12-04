#!/bin/bash

source .env

# Check if python3 is installed
if ! command -v python3 &> /dev/null
then
    echo "python3 could not be found, please install python3."
    exit 1
fi

# Create a new virtual environment for Python
python3 -m venv .venv

# Activate the virtual environment
source .venv/bin/activate 

pip3 install -r requirements.txt


echo "RPC: $TARAXA_RPC"
# Check if the RPC_URL and PRIVATE_KEY are set
if [ -z "$TARAXA_RPC" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$ETH_CLIENT_PROXY" ]; then
  echo "Please set the TARAXA_RPC, PRIVATE_KEY and ETH_CLIENT_PROXY in the .env file"
  exit 1
fi

echo "Calculating current sync committe aggregated PK"

python3 ./script/calculate_sync_committee_hash.py

if [ $? -ne 0 ]; then
  echo "Error calculating currentsync committe aggregated PK"
  exit 1
fi

source .env

# Run the deployment script for TaraClient
res=$(forge script ./script/BlcReplace.s.sol:BlcReplace --force --gas-estimate-multiplier 200 --ffi --rpc-url $TARAXA_RPC --broadcast --legacy | tee /dev/tty)

if [ $? -ne 0 ]; then
  echo "Error running deployment script for TaraClient"
  exit 1
fi

# Deactivate the virtual environment before exiting
deactivate

blcAddress=$(echo "$res" | grep "BeaconLightClient.sol address:" | awk '{print $3}')
echo "BeaconLightClient contract deployed to: $blcAddress"
