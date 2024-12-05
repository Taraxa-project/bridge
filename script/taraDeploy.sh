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


echo "RPC: $TARAXA_RPC"
# Check if the RPC_URL and PRIVATE_KEY are set
if [ -z "$TARAXA_RPC" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$ETH_BRIDGE_ADDRESS" ]; then
  echo "Please set the TARAXA_RPC, ETH_BRIDGE_ADDRESS and PRIVATE_KEY in the .env file"
  exit 1
fi

echo "Calculating current sync committe aggregated PK"

python3 ./script/calculate_sync_committee_hash.py

if [ $? -ne 0 ]; then
  echo "Error calculating current sync committe aggregated PK"
  exit 1
fi

source .env

export PILLAR_CHAIN_INTERVAL=$(curl --silent -X POST --data '{"jsonrpc":"2.0","method":"taraxa_getConfig","params":[],"id":74}' $TARAXA_RPC | jq .result.hardforks.ficus_hf.pillar_blocks_interval | xargs printf "%d\n")

# Run the deployment script for TaraClient
res=$(forge script ./script/Tara.deploy.s.sol:TaraDeployer --force --gas-estimate-multiplier 200 --ffi --rpc-url $TARAXA_RPC --broadcast --legacy | tee /dev/tty)

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
deploymentFile="./deployments/.tara.deployment.$currentTimestamp.json"

echo "TARA_BRIDGE_ADDRESS=$taraBridgeProxy" >> .env

echo "{" > $deploymentFile
echo "  \"taradeploy-$currentTimestamp\": {" >> $deploymentFile
echo "    \"RPC\": \"$TARAXA_RPC\"," >> $deploymentFile
echo "    \"BeaconLightClient\":  \"$blcAddress\"," >> $deploymentFile
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

