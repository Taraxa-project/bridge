#!/bin/bash

echo "#################################"
echo "#                               #"
echo "#          RUN THIS             #"
echo "#       WHEN UPGRADING          #"
echo "#       ETHCLIENT IMPL          #"
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
if [ -z "$RPC_FICUS_PRNET" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$TARA_BRIDGE_PROXY" ] || [ -z "$TARA_CLIENT" ]; then
  echo "Please set the RPC_FICUS_PRNET, TARA_BRIDGE_PROXY, TARA_CLIENT and PRIVATE_KEY in the .env file"
  exit 1
fi

echo "Calculating current sync committe aggregated PK"

python3 ./script/calculate_sync_committee_hash.py

if [ $? -ne 0 ]; then
  echo "Error calculating current sync committe aggregated PK"
  exit 1
fi

source .env

# Run the deployment script for TaraClient
res=$(forge script ./script/EthClient.deploy.s.sol:EthClientUpgraderDeployer --force --ffi --rpc-url $RPC_FICUS_PRNET --broadcast --legacy | tee /dev/tty)

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

oldEthClientProxy=$(echo "$res" | grep "Old EthClient.sol proxy address:" | awk '{print $4}')
newEthClientProxy=$(echo "$res" | grep "New EthClient.sol proxy address:" | awk '{print $4}')
echo "EthClient address upgraded from: $oldEthClientProxy to: $newEthClientProxy"


currentTimestamp=$(date +%s)
deploymentFile="./deployments/.tara.upgrade.ethclient.$currentTimestamp.json"

echo "{" > $deploymentFile
echo "  \"taradeploy-$currentTimestamp\": {" >> $deploymentFile
echo "    \"RPC\": \"$RPC_FICUS_PRNET\"," >> $deploymentFile
echo "    \"BeaconLightClient\":  \"$blcAddress\"," >> $deploymentFile
echo "    \"EthClient\": {" >> $deploymentFile
echo "      \"implAddress\": \"$ethClientImpl\"," >> $deploymentFile
echo "      \"proxyAddress\": \"$ethClientProxy\"" >> $deploymentFile
echo "    }," >> $deploymentFile
echo "    \"TaraBridge\": {" >> $deploymentFile
echo "      \"oldEthClientProxy\": \"$oldEthClientProxy\"," >> $deploymentFile
echo "      \"newEthClientProxy\": \"$newEthClientProxy\"" >> $deploymentFile
echo "    }" >> $deploymentFile
echo "  }" >> $deploymentFile
echo "}" >> $deploymentFile

echo "##############################################################"
echo "#                                                            #"
echo "#    deployment file created: $deploymentFile                #"
echo "#    Deployment successful                                   #"
echo "#                                                            #"
echo "##############################################################"

