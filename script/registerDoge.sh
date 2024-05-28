#!/bin/bash

echo "#################################"
echo "#                               #"
echo "#        REGISTERING DOGE       #"
echo "#                               #"
echo "#################################"

source .env

echo "RPC ETH: $RPC_HOLESKY"
echo "RPC TARA: $RPC_FICUS_PRNET"
# Check if the RPC_URL and PRIVATE_KEY are set
if [ -z "$RPC_FICUS_PRNET" ] || [ -z "$RPC_HOLESKY" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$TARA_BRIDGE_ADDRESS" ]|| [ -z "$ETH_BRIDGE_ADDRESS" ]; then
  echo "Please set the RPC_FICUS_PRNET, RPC_HOLESKY, TARA_BRIDGE_ADDRESS, ETH_BRIDGE_ADDRESS and PRIVATE_KEY in the .env file"
  exit 1
fi

echo "Deploying DOGE on $RPC_HOLESKY"

if [ ! -z "$DOGE_ON_ETH" ]; then
  echo "DOGE_ON_ETH is already set in .env, skipping deployment."
  dogeAddressOnEth=$DOGE_ON_ETH
else

  dogeDeploy=$(forge create src/lib/BridgeDoge.sol:BridgeDoge --legacy --rpc-url=$RPC_HOLESKY --private-key=$PRIVATE_KEY | tee /dev/tty)

  if [ $? -ne 0 ]; then
    echo "Error Deploying DOGE on $RPC_HOLESKY"
    exit 1
  fi

  dogeAddressOnEth=$(echo "$dogeDeploy" | grep "Deployed to:" | awk '{print $3}')
  echo "DOGE_ON_ETH=$dogeAddressOnEth" >> .env

  echo "DOGE_ON_ETH is already set in .env, skipping deployment."
  exit 0
fi



  echo "Deploying DOGE synthetic token on $RPC_FICUS_PRNET"

if [ ! -z "$DOGE_ON_TARA" ]; then
  echo "DOGE_ON_TARA is already set in .env, skipping deployment."
  dogeSyntheticAddressOnTara=$DOGE_ON_TARA
else

  dogeSyntheticDeploy=$(forge create src/lib/TestERC20.sol:TestERC20 --legacy --rpc-url=$RPC_FICUS_PRNET --private-key=$PRIVATE_KEY --constructor-args "Dogecoin" "DOGE" | tee /dev/tty)

  if [ $? -ne 0 ]; then
    echo "Error Deploying DOGE synthetic token on $RPC_FICUS_PRNET"
    exit 1
  fi

  dogeSyntheticAddressOnTara=$(echo "$dogeSyntheticDeploy" | grep "Deployed to:" | awk '{print $3}')
  echo "DOGE_ON_TARA=$dogeSyntheticAddressOnTara" >> .env

fi

echo "Registering DOGE to the bridge"

source .env

registerDogeOnEth=$(forge script script/RegisterDogeOnEth.s.sol:RegisterDogeOnEth --force --rpc-url=$RPC_HOLESKY --private-key=$PRIVATE_KEY  --broadcast --legacy --ffi | tee /dev/tty)

if [ $? -ne 0 ]; then
  echo "Error Registering DOGE on $RPC_HOLESKY"
  exit 1
fi

dogeConnectorProxy=$(echo "$registerDogeOnEth" | grep "ERC20LockingConnector.sol proxy address:" | awk '{print $3}')
dogeConnectorImpl=$(echo "$registerDogeOnEth" | grep "ERC20LockingConnector.sol implementation address:" | awk '{print $3}')
echo "DogeLockingConnector contract deployed to: $dogeConnectorProxy"

registerDogeOnTara=$(forge script script/RegisterDogeOnTara.s.sol:RegisterDogeOnTara --rpc-url=$RPC_FICUS_PRNET --private-key=$PRIVATE_KEY  --broadcast --legacy --force --ffi | tee /dev/tty)

if [ $? -ne 0 ]; then
  echo "Error Registering DOGE on $RPC_FICUS_PRNET"
  exit 1
fi

dogeConnectorProxy=$(echo "$registerDogeOnTara" | grep "ERC20MintingConnector.sol proxy address:" | awk '{print $4}')
dogeConnectorImpl=$(echo "$registerDogeOnTara" | grep "ERC20MintingConnector.sol implementation address:" | awk '{print $4}')

echo "DogeMintingConnector contract deployed to: $dogeConnectorProxy"

currentTimestamp=$(date +%s)
deploymentFile="./deployments/.doge.deployment.$currentTimestamp.json"
echo "{" > $deploymentFile
echo "  \"dogedeploy-$currentTimestamp\": {" >> $deploymentFile
echo "    \"RPC_ETH\": \"$RPC_HOLESKY\"," >> $deploymentFile
echo "    \"RPC_TARA\": \"$RPC_FICUS_PRNET\"," >> $deploymentFile
echo "    \"DOGE\": {" >> $deploymentFile
echo "      \"address\": \"$dogeAddressOnEth\"," >> $deploymentFile
echo "      \"syntheticAddress\": \"$dogeSyntheticAddressOnTara\"" >> $deploymentFile
echo "    }," >> $deploymentFile
echo "    \"DOGE_CONNECTOR_ETH\": {" >> $deploymentFile
echo "      \"implAddress\": \"$dogeConnectorImpl\"," >> $deploymentFile
echo "      \"proxyAddress\": \"$dogeConnectorProxy\"" >> $deploymentFile
echo "    }," >> $deploymentFile
echo "    \"DOGE_CONNECTOR_TARA\": {" >> $deploymentFile
echo "      \"implAddress\": \"$dogeConnectorImpl\"," >> $deploymentFile
echo "      \"proxyAddress\": \"$dogeConnectorProxy\"" >> $deploymentFile
echo "    }" >> $deploymentFile
echo "  }" >> $deploymentFile
echo "}" >> $deploymentFile

echo "##############################################################"
echo "#                                                            #"
echo "#    DOGE deployed                                           #"
echo "#    deployment file created: $deploymentFile                #"
echo "#                                                            #"
echo "##############################################################"

