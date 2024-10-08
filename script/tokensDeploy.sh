#!/bin/bash

echo "#################################"
echo "#                               #"
echo "#          RUN   THIS           #"
echo "#            FIRST              #"
echo "#                               #"
echo "#################################"

source .env

echo "Holesky RPC: $ETHEREUM_RPC"
echo "Tara RPC: $TARAXA_RPC"

echo "Running deployment script for TARA on ETH"

export SYMBOL="TARA"
export NAME="Taraxa"
# # Deploy the Tara token to Holesky using forge create
resTara=$(forge script ./script/Token.deploy.s.sol:TokenDeployer --rpc-url $ETHEREUM_RPC --broadcast --legacy --ffi | tee /dev/tty)

if [ $? -ne 0 ]; then
  echo "Error deploying Tara token"
  exit 1
fi

# Extract the proxy and implementation addresses of the deployed contract
taraAddress=$(echo "$resTara" | grep "TestERC20 address:" | awk '{print $3}')

echo "TARA token on Eth deployed to: $taraAddress"

echo "TARA_ADDRESS_ON_ETH=$taraAddress" >> .env

echo "Running deployment script for ETH on TARA"
# Deploy the Eth token to Taraxa using forge create
export SYMBOL="ETH"
export NAME="Ethereum"

resEth=$(forge script ./script/Token.deploy.s.sol:TokenDeployer --rpc-url $TARAXA_RPC --broadcast --legacy --ffi | tee /dev/tty)

if [ $? -ne 0 ]; then
  echo "Error deploying Tara token"
  exit 1
fi

# Extract the proxy and implementation addresses of the deployed contract
ethAddress=$(echo "$resEth" | grep "TestERC20 address:" | awk '{print $3}')

echo "Eth token on Tara deployed to: $ethAddress"

echo "ETH_ADDRESS_ON_TARA=$ethAddress" >> .env

currentTimestamp=$(date +%s)
deploymentFile="./deployments/.token.deployment.$currentTimestamp.json"
echo "{" > $deploymentFile
echo "  \"tokendeploy-$currentTimestamp\": {" >> $deploymentFile
echo "    \"TARA\": {" >> $deploymentFile
echo "      \"address\": \"$taraAddress\"," >> $deploymentFile
echo "      \"RPC\": \"$ETHEREUM_RPC\"" >> $deploymentFile
echo "    }," >> $deploymentFile
echo "    \"ETH\": {" >> $deploymentFile
echo "      \"address\": \"$ethAddress\"," >> $deploymentFile
echo "      \"RPC\": \"$TARAXA_RPC\"" >> $deploymentFile
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