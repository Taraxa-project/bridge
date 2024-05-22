#!/bin/bash

echo "#################################"
echo "#                               #"
echo "#          RUN THIS             #"
echo "#    AFTER ETH DEPLOYMENT       #"
echo "#                               #"
echo "#################################"

echo ""

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


echo "RPC: $RPC_FICUS_PRNET"
# Check if the RPC_URL and PRIVATE_KEY are set
if [ -z "$RPC_FICUS_PRNET" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$ETH_BRIDGE_ADDRESS" ] || [ -z "$TARA_CLIENT" ]; then
  echo "Please set the RPC_FICUS_PRNET, ETH_BRIDGE_ADDRESS, TARA_CLIENT and PRIVATE_KEY in the .env file"
  exit 1
fi

echo "Calculating current sync committe aggregated PK"

python3 src/scripts/calculate_sync_committee_hash.py

if [ $? -ne 0 ]; then
  echo "Error calculating current sync committe aggregated PK"
  exit 1
fi
# Run the deployment script for TaraClient
res=$(forge script src/scripts/Tara.deploy.s.sol:TaraDeployer --force --via-ir --rpc-url $RPC_FICUS_PRNET --broadcast --legacy | tee /dev/tty)

if [ $? -ne 0 ]; then
  echo "Error running deployment script for TaraClient"
  exit 1
fi

# Deactivate the virtual environment before exiting
deactivate

blcAddress=$(echo "$res" | grep "BeaconLightClient.sol address:" | awk '{print $3}')
echo "BeaconLightClient contract deployed to: $blcAddress"

ethClientProxy=$(echo "$res" | grep "EthClient.sol proxy address:" | awk '{print $4}')
ethClientImpl=$(echo "$res" | grep "EthClient.sol implementation address:" | awk '{print $4}')
echo "EthClient contract deployed to: $ethClientProxy"

taraBridgeProxy=$(echo "$res" | grep "TaraBridge.sol proxy address:" | awk '{print $4}')
taraBridgeImpl=$(echo "$res" | grep "TaraBridge.sol implementation address:" | awk '{print $4}')
echo "TaraBridge contract deployed to: $taraBridgeProxy"

taraConnectorProxy=$(echo "$res" | grep "NativeConnector.sol proxy address:" | awk '{print $4}')
taraConnectorImpl=$(echo "$res" | grep "NativeConnector.sol implementation address:" | awk '{print $4}')
echo "TaraConnector contract deployed to: $taraConnectorProxy"

ethMintingConnectorProxy=$(echo "$res" | grep "ERC20MintingConnector.sol proxy address:" | awk '{print $4}')
ethMintingConnectorImpl=$(echo "$res" | grep "ERC20MintingConnector.sol implementation address:" | awk '{print $4}')
echo "EthMintingConnector contract deployed to: $ethMintingConnectorProxy"


currentTimestamp=$(date +%s)
deploymentFile=".tara.deployment.$currentTimestamp.json"

echo "{" > $deploymentFile
echo "  \"taradeploy-$currentTimestamp\": {" >> $deploymentFile
echo "    \"RPC\": \"$RPC_FICUS_PRNET\"," >> $deploymentFile
echo "    \"EthClient\": {" >> $deploymentFile
echo "      \"implAddress\": \"$ethClientImpl\"," >> $deploymentFile
echo "      \"proxyAddress\": \"$ethClientProxy\"" >> $deploymentFile
echo "    }," >> $deploymentFile
echo "    \"TaraBridge\": {" >> $deploymentFile
echo "      \"implAddress\": \"$taraBridgeImpl\"," >> $deploymentFile
echo "      \"proxyAddress\": \"$taraBridgeProxy\"" >> $deploymentFile
echo "    }," >> $deploymentFile
echo "    \"ERC20MintingConnector\": {" >> $deploymentFile
echo "      \"implAddress\": \"$ethMintingConnectorImpl\"," >> $deploymentFile
echo "      \"proxyAddress\": \"$ethMintingConnectorProxy\"" >> $deploymentFile
echo "    }," >> $deploymentFile
echo "    \"NativeConnector\": {" >> $deploymentFile
echo "      \"implAddress\": \"$taraConnectorImpl\"," >> $deploymentFile
echo "      \"proxyAddress\": \"$taraConnectorProxy\"" >> $deploymentFile
echo "    }" >> $deploymentFile
echo "  }" >> $deploymentFile
echo "}" >> $deploymentFile

echo "##############################################################"
echo "#                                                            #"
echo "#    deployment file created: $deploymentFile                #"
echo "#    Deployment successful                                   #"
echo "#                                                            #"
echo "##############################################################"

