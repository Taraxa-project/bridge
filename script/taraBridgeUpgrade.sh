#!/bin/bash

echo "#################################"
echo "#                               #"
echo "#          RUN THIS             #"
echo "#       WHEN UPGRADING          #"
echo "#       TARA BRIDGE IMPL        #"
echo "#                               #"
echo "#################################"

echo ""

source .env

echo "RPC: $TARAXA_RPC"
if [ -z "$TARAXA_RPC" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$TARA_BRIDGE_ADDRESS" ]; then
  echo "Please set the TARAXA_RPC, TARA_BRIDGE_ADDRESS and PRIVATE_KEY in the .env file"
  exit 1
fi

# Run the deployment script for TaraClient
res=$(forge script ./script/TaraBridgeUpgrade.s.sol:TaraBridgeUpgrade --force --ffi --rpc-url $TARAXA_RPC --broadcast --legacy | tee /dev/tty)