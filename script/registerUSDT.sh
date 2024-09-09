#!/bin/bash

echo "#################################"
echo "#                               #"
echo "#        REGISTERING USDT       #"
echo "#                               #"
echo "#################################"

source .env

echo "RPC ETH: $ETHEREUM_RPC"
echo "RPC TARA: $TARAXA_RPC"
# Check if the RPC_URL and PRIVATE_KEY are set
if [ -z "$TARAXA_RPC" ] || [ -z "$ETHEREUM_RPC" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$TARA_BRIDGE_ADDRESS" ]|| [ -z "$ETH_BRIDGE_ADDRESS" ]; then
  echo "Please set the TARAXA_RPC, ETHEREUM_RPC, TARA_BRIDGE_ADDRESS, ETH_BRIDGE_ADDRESS and PRIVATE_KEY in the .env file"
  exit 1
fi

echo "Deploying USDT on $ETHEREUM_RPC"

if [ ! -z "$USDT_ON_ETH" ]; then
  echo "USDT_ON_ETH is already set in .env, skipping deployment."
  usdtAddressOnEth=$USDT_ON_ETH
else

  usdtDeploy=$(forge create src/lib/BridgeUSDT.sol:BridgeUSDT --rpc-url=$ETHEREUM_RPC --private-key=$PRIVATE_KEY | tee /dev/tty)

  if [ $? -ne 0 ]; then
    echo "Error Deploying USDT on $ETHEREUM_RPC"
    exit 1
  fi

  usdtAddressOnEth=$(echo "$usdtDeploy" | grep "Deployed to:" | awk '{print $3}')
  echo "USDT_ON_ETH=$usdtAddressOnEth" >> .env

  echo "USDT_ON_ETH deployed at $usdtAddressOnEth"
fi



echo "Deploying USDT synthetic token on $TARAXA_RPC"

if [ ! -z "$USDT_ON_TARA" ]; then
  echo "USDT_ON_TARA is already set in .env, skipping deployment."
  usdtSyntheticAddressOnTara=$USDT_ON_TARA
else

  usdtSyntheticDeploy=$(forge create src/lib/USDT.sol:USDT --legacy --rpc-url=$TARAXA_RPC --private-key=$PRIVATE_KEY | tee /dev/tty)

  if [ $? -ne 0 ]; then
    echo "Error Deploying USDT synthetic token on $TARAXA_RPC"
    exit 1
  fi

  usdtSyntheticAddressOnTara=$(echo "$usdtSyntheticDeploy" | grep "Deployed to:" | awk '{print $3}')
  echo "USDT_ON_TARA=$usdtSyntheticAddressOnTara" >> .env

fi

echo "Registering USDT to the bridge"

source .env

registerUSDTOnEth=$(forge script script/RegisterUSDTOnEth.s.sol:RegisterUSDTOnEth --force --rpc-url=$ETHEREUM_RPC --private-key=$PRIVATE_KEY  --broadcast --legacy --ffi | tee /dev/tty)

if [ $? -ne 0 ]; then
  echo "Error Registering USDT on $ETHEREUM_RPC"
  exit 1
fi

usdtConnectorProxyEth=$(echo "$registerUSDTOnEth" | grep "ERC20LockingConnector.sol proxy address:" | awk '{print $4}')
usdtConnectorImplEth=$(echo "$registerUSDTOnEth" | grep "ERC20LockingConnector.sol implementation address:" | awk '{print $4}')
echo "USDTLockingConnector contract deployed to: $usdtConnectorProxyEth"

registerUSDTOnTara=$(forge script script/RegisterUSDTOnTara.s.sol:RegisterUSDTOnTara --rpc-url=$TARAXA_RPC --private-key=$PRIVATE_KEY  --broadcast --legacy --force --ffi | tee /dev/tty)

if [ $? -ne 0 ]; then
  echo "Error Registering USDT on $TARAXA_RPC"
  exit 1
fi

usdtConnectorProxyTara=$(echo "$registerUSDTOnTara" | grep "ERC20MintingConnector.sol proxy address:" | awk '{print $4}')
usdtConnectorImplTara=$(echo "$registerUSDTOnTara" | grep "ERC20MintingConnector.sol implementation address:" | awk '{print $4}')

echo "USDTMintingConnector contract deployed to: $usdtConnectorProxyTara"

currentTimestamp=$(date +%s)
deploymentFile="./deployments/.usdt.deployment.$currentTimestamp.json"
echo "{" > $deploymentFile
echo "  \"usdtdeploy-$currentTimestamp\": {" >> $deploymentFile
echo "    \"RPC_ETH\": \"$ETHEREUM_RPC\"," >> $deploymentFile
echo "    \"RPC_TARA\": \"$TARAXA_RPC\"," >> $deploymentFile
echo "    \"USDT\": {" >> $deploymentFile
echo "      \"address\": \"$usdtAddressOnEth\"," >> $deploymentFile
echo "      \"syntheticAddress\": \"$usdtSyntheticAddressOnTara\"" >> $deploymentFile
echo "    }," >> $deploymentFile
echo "    \"USDT_CONNECTOR_ETH\": {" >> $deploymentFile
echo "      \"implAddress\": \"$usdtConnectorImplEth\"," >> $deploymentFile
echo "      \"proxyAddress\": \"$usdtConnectorProxyEth\"" >> $deploymentFile
echo "    }," >> $deploymentFile
echo "    \"USDT_CONNECTOR_TARA\": {" >> $deploymentFile
echo "      \"implAddress\": \"$usdtConnectorImplTara\"," >> $deploymentFile
echo "      \"proxyAddress\": \"$usdtConnectorProxyTara\"" >> $deploymentFile
echo "    }" >> $deploymentFile
echo "  }" >> $deploymentFile
echo "}" >> $deploymentFile

echo "##############################################################"
echo "#                                                            #"
echo "#    USDT deployed                                           #"
echo "#    deployment file created: $deploymentFile                #"
echo "#                                                            #"
echo "##############################################################"

