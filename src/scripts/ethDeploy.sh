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
if [ -z "$RPC_HOLESKY" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$TARA_ADDRESS_ON_ETH" ]|| [ -z "$ETH_ADDRESS_ON_TARA" ]; then
  echo "Please set the RPC_HOLESKY, TARA_ADDRESS_ON_ETH, ETH_ADDRESS_ON_TARA and PRIVATE_KEY in the .env file"
  exit 1
fi

echo "Running deployment script for TaraClient & EthBridge"

res=$(forge script src/scripts/Eth.deploy.s.sol:EthDeployer --rpc-url $RPC_HOLESKY --broadcast --legacy --force | tee /dev/tty)

if [ $? -ne 0 ]; then
  echo "Error running deployment script for EthBridge"
  echo "$res"
  exit 1
fi

# Extract the address of the deployed contract
ethBridgeProxy=$(echo "$res" | grep "EthBridge.sol proxy address:" | awk '{print $4}')
ethBridgeImpl=$(echo "$res" | grep "EthBridge.sol implementation address:" | awk '{print $4}')
echo "Eth bridge contract deployed to: $ethBridgeProxy"
echo "ETH_BRIDGE_ADDRESS=$ethBridgeProxy" >> .env

taraClientOnEthProxy=$(echo "$res" | grep "TaraClient.sol proxy address:" | awk '{print $4}')
taraClientOnEthImpl=$(echo "$res" | grep "TaraClient.sol implementation address:" | awk '{print $4}')

mintingConnectorOnEthProxy=$(echo "$res" | grep "ERC20MintingConnector.sol proxy address:" | awk '{print $4}')
mintingConnectorOnEthImpl=$(echo "$res" | grep "ERC20MintingConnector.sol implementation address:" | awk '{print $4}')

nativeConnectorOnEthProxy=$(echo "$res" | grep "NativeConnector.sol proxy address:" | awk '{print $4}')
nativeConnectorOnEthImpl=$(echo "$res" | grep "NativeConnector.sol implementation address:" | awk '{print $4}')

echo "Tara client contract deployed to: $taraClientOnEthProxy"
echo "TARA_CLIENT=$taraClientOnEthProxy" >> .env

currentTimestamp=$(date +%s)
deploymentFile=".eth.deployment.$currentTimestamp.json"
echo "{" > $deploymentFile
echo "  \"ethdeploy-$currentTimestamp\": {" >> $deploymentFile
echo "    \"RPC\": \"$RPC_HOLESKY\"," >> $deploymentFile
echo "    \"TaraClient\": {" >> $deploymentFile
echo "      \"implAddress\": \"$taraClientOnEthImpl\"," >> $deploymentFile
echo "      \"proxyAddress\": \"$taraClientOnEthProxy\"" >> $deploymentFile
echo "    }," >> $deploymentFile
echo "    \"EthBridge\": {" >> $deploymentFile
echo "      \"implAddress\": \"$ethBridgeImpl\"," >> $deploymentFile
echo "      \"proxyAddress\": \"$ethBridgeProxy\"" >> $deploymentFile
echo "    }," >> $deploymentFile
echo "    \"ERC20MintingConnector\": {" >> $deploymentFile
echo "      \"implAddress\": \"$mintingConnectorOnEthImpl\"," >> $deploymentFile
echo "      \"proxyAddress\": \"$mintingConnectorOnEthProxy\"" >> $deploymentFile
echo "    }," >> $deploymentFile
echo "    \"NativeConnector\": {" >> $deploymentFile
echo "      \"implAddress\": \"$nativeConnectorOnEthImpl\"," >> $deploymentFile
echo "      \"proxyAddress\": \"$nativeConnectorOnEthProxy\"" >> $deploymentFile
echo "    }" >> $deploymentFile
echo "  }" >> $deploymentFile
echo "}" >> $deploymentFile

echo "##############################################################"
echo "#                                                            #"
echo "#    ETH_BRIDGE_ADDRESS added to env                         #"
echo "#    TARA_CLIENT added to env                                #"
echo "#    deployment file created: $deploymentFile                #"
echo "#    Proceed with tara-deploy                                #"
echo "#                                                            #"
echo "##############################################################"
