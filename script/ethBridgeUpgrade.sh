#!/bin/bash

echo "#################################"
echo "#                               #"
echo "#          RUN THIS             #"
echo "#       WHEN UPGRADING          #"
echo "#       ETH BRIDGE IMPL         #"
echo "#                               #"
echo "#################################"

echo ""

source .env

echo "RPC: $ETHEREUM_RPC"
if [ -z "$ETHEREUM_RPC" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$ETH_BRIDGE_ADDRESS" ]; then
  echo "Please set the ETHEREUM_RPC, ETH_BRIDGE_ADDRESS and PRIVATE_KEY in the .env file"
  exit 1
fi

# Run the deployment script for TaraClient
res=$(forge script ./script/EthBridgeUpgrade.s.sol:EthBridgeUpgrade --force --ffi --rpc-url $ETHEREUM_RPC --broadcast | tee /dev/tty)