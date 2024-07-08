# Bridge

Bridge smart contracts that allow users to move states between Ethereum and Taraxa chains.

## Official Testnet Deployment

At the end of June 2024, the bridge was deployed on the official Taraxa testnet and serves as an active avenue to bridge tokens from ETH Holes to TARA and vice versa.

You can find out more about the deployment details in the [TESTNET.md](TESTNET.md) file.

## Where to find important information

- [DEPLOY.md](DEPLOY.md) - Deployment addresses
- [FLOWS.md](FLOWS.md) - Description of main flows
- [INTEGRATION.md](INTEGRATION.md) - Integration manual

### Main contracts

- [BridgeBase.sol](src/lib/BridgeBase.sol)
- [EthBridge.sol](src/eth/EthBridge.sol)
- [TaraBridge.sol](src/tara/TaraBridge.sol)
- [TokenConnectorLogic.sol](src/connectors/TokenConnectorLogic.sol)
- [NativeConnector.sol](src/connectors/NativeConnector.sol)
- [ERC20LockingConnector.sol](src/connectors/ERC20LockingConnector.sol)
- [ERC20MintingConnector.sol](src/connectors/ERC20MintingConnector.sol)

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

- [ERC20LockingConnector.sol](./src/connectors/ERC20LockingConnector.sol)
- [ERC20MintingConnector.sol](./src/connectors/ERC20MintingConnector.sol)

### Scripts

The root [Makefile](./Makefile) contains a few useful commands that are used for development and testing.

```shell
make test
```

The [scripts folder](./scripts) contains a few useful scripts that are used for development, deployment, contract registration and testing.
