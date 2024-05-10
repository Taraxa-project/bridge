#!/bin/bash

echo "#################################"
echo "#                               #"
echo "#          RUN   THIS           #"
echo "#            FIRST              #"
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

# Deploy the Tara token to Holesky using forge create
res=$(forge create --via-ir --constructor-args "Taraxa" "TARA" --rpc-url $RPC_HOLESKY --private-key $PRIVATE_KEY src/lib/TestERC20.sol:TestERC20)

if [ $? -ne 0 ]; then
  echo "Error deploying Tara token"
  exit 1
fi

# Extract the address of the deployed contract
taraAddress=$(echo "$res" | grep "Deployed to:" | awk '{print $3}')

echo "Deployed to: $taraAddress"

echo "ETH_TARA_ADDRESS=$taraAddress" >> .env

echo "Running deployment script for TaraClient & EthBridge"

ethBridge=$(forge script src/scripts/Eth.deploy.s.sol:EthDeployer --via-ir --rpc-url $RPC_HOLESKY --broadcast --legacy)

if [ $? -ne 0 ]; then
  echo "Error running deployment script for EthBridge"
  exit 1
fi

echo "$ethBridge" >> deployment-eth.log
