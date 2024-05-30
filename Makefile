-include .env

.PHONY: all test clean deploy-anvil

all: clean update build

get-foundry:; foundryup -v nightly-f625d0fa7c51e65b4bf1e8f7931cd1c6e2e285e9

# Clean the repo
clean  :; forge clean

doc :; forge doc --build --out documentation --serve --port 4000 

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test --ffi --force

snapshot :; forge snapshot --ffi

# solhint should be installed globally
lint :; solhint src/**/*.sol && solhint src/*.sol

anvil :; anvil -m 'test test test test test test test test test test test junk'

tokens-deploy :; bash ./script/tokensDeploy.sh

eth-deploy :; bash ./script/ethDeploy.sh

tara-deploy :; bash ./script/taraDeploy.sh

bridge-deploy :; bash ./script/deploySymmetricBridge.sh

add-deployment-metadata :; bash ./script/addToDeployMarkdown.sh

doge :; bash ./script/registerDoge.sh

-include ${FCT_PLUGIN_PATH}/makefile-external

