#!/bin/bash

echo "#################################"
echo "#                               #"
echo "#        RUN THIS AFTER         #"
echo "#    THE TOKENS DEPLOYMENT      #"
echo "#                               #"
echo "#################################"

source .env

echo "RPC: $RPC_HOLESKY"
# Check if the RPC_URL and PRIVATE_KEY are set
if [ -z "$RPC_HOLESKY" ] || [ -z "$PRIVATE_KEY" ]; then
  echo "Please set the RPC_HOLESKY and PRIVATE_KEY in the .env file"
  exit 1
fi

echo "Deploying TaraClient contract"

echo "Running deployment script for TaraClient & EthBridge"

res=$(forge script src/scripts/Eth.deploy.s.sol:EthDeployer --via-ir --rpc-url $RPC_HOLESKY --broadcast --legacy)

if [ $? -ne 0 ]; then
  echo "Error running deployment script for EthBridge"
  exit 1
fi

# Extract the address of the deployed contract
ethBridge=$(echo "$res" | grep "Eth Bridge address:" | awk '{print $4}')
echo "Eth bridge contract deployed to: $ethBridge"
echo "ETH_BRIDGE_ADDRESS=$ethBridge" >> .env

taraClientOnEth=$(echo "$res" | grep "Tara Client address:" | awk '{print $4}')
echo "Tara client contract deployed to: $taraClientOnEth"
echo "TARA_CLIENT=$taraClientOnEth" >> .env

echo "$res" >> deployment-eth.log
