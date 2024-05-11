#!/bin/bash

echo "#################################"
echo "#                               #"
echo "#          RUN   THIS           #"
echo "#            FIRST              #"
echo "#                               #"
echo "#################################"

source .env

echo "Holesky RPC: $RPC_HOLESKY"
echo "Tara RPC: $RPC_FICUS_PRNET"

# # Deploy the Tara token to Holesky using forge create
export SYMBOL="TARA"
export NAME="Taraxa"
res=$(forge script src/scripts/Token.deploy.s.sol:TokenDeployer --via-ir --rpc-url $RPC_HOLESKY --broadcast --legacy --force --slow)

if [ $? -ne 0 ]; then
  echo "Error deploying Tara token"
  exit 1
fi

# Extract the address of the deployed contract
taraAddress=$(echo "$res" | grep "Deployed to:" | awk '{print $3}')

echo "TARA token on Eth deployed to: $taraAddress"

echo "TARA_ADDRESS_ON_ETH=$taraAddress" >> .env

# Deploy the Eth token to Taraxa using forge create
export SYMBOL="ETH"
export NAME="Ethereum"
res=$(forge script src/scripts/Token.deploy.s.sol:TokenDeployer --via-ir --rpc-url $RPC_FICUS_PRNET --broadcast --legacy --force --slow)

if [ $? -ne 0 ]; then
  echo "Maybe Eth token deployment failed. Check the receipt"
fi

# Extract the address of the deployed contract
ethAddress=$(echo "$res" | grep "Deployed to:" | awk '{print $3}')

echo "Eth token on Tara deployed to: $ethAddress"

echo "ETH_ADDRESS_ON_TARA=$ethAddress" >> .env