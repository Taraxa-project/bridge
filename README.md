## Bridge

Bridge smart contracts that allow users to move states between Ethereum and Taraxa chains.

### Main contracts 

* [EthBridge.sol](src/eth/EthBridge.sol)
* [TaraBridge.sol](src/tara/TaraBridge.sol)

There are main contracts on both chains that are finalizing states(changes list) and applies state changes from the other chain. Changes are verified against the Bridge Root that is requested from the light clients and is verified against the other chain consensus. 

### Light clients

#### Ethereum light client

[beacon-light-client](https://github.com/darwinia-network/beacon-light-client)

[EthClient.sol](src/tara/EthClient.sol)

Ethereum light client is deployed on Taraxa side and it is accepting Ethereum block headers and verifying them against the Ethereum consensus. So after the finalization of Ethereum header we can take state root from it and verify Bridge Root against it.


#### Taraxa light client

[TaraClient.sol](src/eth/TaraClient.sol)

Taraxa light client will verify Taraxa Pillar blocks that are special type of blocks for this purpose. Pillar block will have Bridge Root in it, so we can directly use Bridge Root from it. 

### Connectors

Connectors are contracts that are deployed on both chains and they are: 
1. Finalizing state to transfer it to another chain.
2. Applies changes from the other chain.

Interface could be found at [IBridgeConnector.sol](./src/connectors/IBridgeConnector.sol)

Examples of connectors:
* [ERC20LockingConnector.sol](./src/connectors/ERC20LockingConnector.sol)
* [ERC20MintingConnector.sol](./src/connectors/ERC20MintingConnector.sol)


## Foundry Documentation

https://book.getfoundry.sh/

## Usage

### Test

```shell
$ forge test --via-ir
```

