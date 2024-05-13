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

export SYMBOL="TARA"
export NAME="Taraxa"
forge script src/scripts/Token.deploy.s.sol:TokenDeployer --via-ir --rpc-url $RPC_HOLESKY --legacy --force --slow

if [ $? -ne 0 ]; then
  echo "Error running DRY RUN for Tara token"
  exit 1
fi

# # Deploy the Tara token to Holesky using forge create
res=$(forge script src/scripts/Token.deploy.s.sol:TokenDeployer --via-ir --rpc-url $RPC_HOLESKY --broadcast --legacy --force --slow)

if [ $? -ne 0 ]; then
  echo "Error deploying Tara token"
  exit 1
fi

# Extract the proxy and implementation addresses of the deployed contract
taraProxyAddress=$(echo "$res" | grep "TestERC20 proxy:" | awk '{print $3}')
taraImplementationAddress=$(echo "$res" | grep "TestERC20 implementation:" | awk '{print $3}')

echo "TARA token on Eth deployed to: $taraProxyAddress"

echo "TARA_ADDRESS_ON_ETH=$taraProxyAddress" >> .env

echo "Running deployment script for TARA on ETH >> Checking DRY RUN"
# Deploy the Eth token to Taraxa using forge create
export SYMBOL="ETH"
export NAME="Ethereum"
forge script src/scripts/Token.deploy.s.sol:TokenDeployer --via-ir --rpc-url $RPC_FICUS_PRNET --legacy --force --slow

if [ $? -ne 0 ]; then
  echo "Error running DRY RUN for ETH token"
  exit 1
fi


res=$(forge script src/scripts/Token.deploy.s.sol:TokenDeployer --via-ir --rpc-url $RPC_FICUS_PRNET --broadcast --legacy --force --slow)

if [ $? -ne 0 ]; then
  echo "Error deploying Tara token"
  exit 1
fi

# Extract the proxy and implementation addresses of the deployed contract
ethProxyAddress=$(echo "$res" | grep "TestERC20 proxy:" | awk '{print $3}')
ethImplementationAddress=$(echo "$res" | grep "TestERC20 implementation:" | awk '{print $3}')

echo "Eth token on Tara deployed to: $ethProxyAddress"

echo "ETH_ADDRESS_ON_TARA=$ethProxyAddress" >> .env

currentTimestamp=$(date +%s)
deploymentFile=".token.deployment.$currentTimestamp.json"
echo "{" > $deploymentFile
echo "  \"tokendeploy-$currentTimestamp\": {" >> $deploymentFile
echo "    \"TARA\": {" >> $deploymentFile
echo "      \"implAddress\": \"$taraImplementationAddress\"," >> $deploymentFile
echo "      \"proxyAddress\": \"$taraProxyAddress\"," >> $deploymentFile
echo "      \"RPC\": \"$RPC_HOLESKY\"" >> $deploymentFile
echo "    }," >> $deploymentFile
echo "    \"ETH\": {" >> $deploymentFile
echo "      \"implAddress\": \"$ethImplementationAddress\"," >> $deploymentFile
echo "      \"proxyAddress\": \"$ethProxyAddress\"," >> $deploymentFile
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