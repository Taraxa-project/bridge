-include .env

.PHONY: all test clean deploy-anvil

all: clean remove install update build

get-foundry:; foundryup -v nightly-f625d0fa7c51e65b4bf1e8f7931cd1c6e2e285e9

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std --no-commit && forge install darwinia-network/beacon-light-client --no-commit && forge install OpenZeppelin/openzeppelin-contracts --no-commit

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

