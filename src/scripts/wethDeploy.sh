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

echo "Running deployment script for TARA on ETH >> Checking DRY RUN"

export SYMBOL="WTARA"
export NAME="Wrapped Taraxa"
forge script src/scripts/WETH9.deploy.s.sol:WrapperDeployer --via-ir --rpc-url $RPC_HOLESKY --legacy --slow

if [ $? -ne 0 ]; then
  echo "Error running DRY RUN for Tara token"
  exit 1
fi

# # Deploy the Tara token to Holesky using forge create
res=$(forge script src/scripts/WETH9.deploy.s.sol:WrapperDeployer --via-ir --rpc-url $RPC_HOLESKY --broadcast --legacy --slow)

if [ $? -ne 0 ]; then
  echo "Error deploying Tara token"
  exit 1
fi

# Extract the proxy and implementation addresses of the deployed contract
wtaraAddress=$(echo "$res" | grep "Wrapper address:" | awk '{print $3}')

echo "TARA token on Eth deployed to: $wtaraAddress"

echo "TARA_ADDRESS_ON_ETH=$wtaraAddress" >> .env

echo "Running deployment script for TARA on ETH >> Checking DRY RUN"
# Deploy the Eth token to Taraxa using forge create
export SYMBOL="WETH"
export NAME="Wrapped Ethereum"
forge script src/scripts/WETH9.deploy.s.sol:WrapperDeployer --via-ir --rpc-url $RPC_FICUS_PRNET --legacy --slow

if [ $? -ne 0 ]; then
  echo "Error running DRY RUN for ETH token"
  exit 1
fi


res=$(forge script src/scripts/WETH9.deploy.s.sol:WrapperDeployer --via-ir --rpc-url $RPC_FICUS_PRNET --broadcast --legacy --slow)

if [ $? -ne 0 ]; then
  echo "Error deploying WETH token"
  exit 1
fi

# Extract the proxy and implementation addresses of the deployed contract
wethAddress=$(echo "$res" | grep "Wrapper address:" | awk '{print $3}')

echo "Eth token on Tara deployed to: $wethAddress"

echo "ETH_ADDRESS_ON_TARA=$wethAddress" >> .env

currentTimestamp=$(date +%s)
deploymentFile=".token.deployment.$currentTimestamp.json"
echo "{" > $deploymentFile
echo "  \"tokendeploy-$currentTimestamp\": {" >> $deploymentFile
echo "    \"TARA\": {" >> $deploymentFile
echo "      \"address\": \"$wtaraAddress\"," >> $deploymentFile
echo "      \"RPC\": \"$RPC_HOLESKY\"" >> $deploymentFile
echo "    }," >> $deploymentFile
echo "    \"ETH\": {" >> $deploymentFile
echo "      \"address\": \"$wethAddress\"," >> $deploymentFile
echo "      \"RPC\": \"$RPC_FICUS_PRNET\"" >> $deploymentFile
echo "    }" >> $deploymentFile
echo "  }" >> $deploymentFile
echo "}" >> $deploymentFile


echo "##############################################################"
echo "#                                                            #"
echo "#    TARA_ADDRESS_ON_ETH added to env                        #"
echo "#    ETH_ADDRESS_ON_TARA added to env                        #"
echo "#    deployment file created: $deploymentFile                #"
echo "#    Proceed with eth-deploy                                 #"
echo "#                                                            #"
echo "##############################################################"