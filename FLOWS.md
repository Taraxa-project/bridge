# Ficus Bridge flows

This document describes setup, maintenance and user flows for the Ficus Bridge.

## General Flow & Setup Requirements

![Setup Flow](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/Taraxa-project/bridge/master/plantuml/setup.iuml)

The system is set up by 2 main contracts on both ends:

- `TaraBridge` on Taraxa side that uses the `TaraClient` to update the state and finalize epochs.
- `EthBridge` on Holesky side that uses the `EthClient` to update the state and finalize epochs.

In order to be able to bridge tokens, the system must be set up by a relayer. The relayer is responsible for updating the state on both sides and finalizing epochs.

### Incentives

Updating the state in the clients is not incentivised and after the Ficus HF will be done by the Taraxa Core team via a specific relayer account.

**Note**: This state update is mainly setting up the voting committee data for the ETHClient on the Taraxa side(migrating ETH state) and setting the last Pillar block data on the TARAClient on the ETH side(migrating TARA state).

However, finalising states and applying states on both ends are incentivised by paying the relayers a **specific multiplier on the gas fees they used** to prectically facilitate balance migration from origin to destination. This **fee** is `>=100` depending on the gas price.

**Note**: Anyone can run a relayer by using a wallet address that has enough ETH and TARA to pay for the gas fees and start earning these incentives. However, by design, _one epoch can be finalised and applied only once regardless of how many relayers are trying to do so_. Therefore, if multiple relayers are trying to finalise the same epoch, the quickest one will be rewarded and all other relayers will lose the gas used until their respective transactions are reverted.

#### Design reasoning

Ficus bridge is a simple contract setup that first and foremost, migrates state from one chain to another. It is designed to be as simple as possible while still being able to handle the most common use-cases. Therefore, if one state is validated and migrated, there's no need to set up complex relayer systems to reach consensus on what state to apply: _simply finalise, validate and apply the state on both sides_.

## Token registration

While permissionless by design, in order to be able to bridge tokens, Ficus Bridge requires the registration of the tokens on both sides. This is done by the calling the [registerContract](./src/lib/BridgeBase.sol#142) method on each side. This method register a special smart contract called _Connector_ that acts as multi-faces utility contract for the Bridge. Without a connector, the bridge will not be able to interact with the tokens on the respective chain.

### Connector requirements

In order to be able to interact with the bridge, the connector must:

- 1. Have enough balance to cover its registration fee. This is a one-time fee that will be paid to the bridge in native assets of the respective chain. The main reasoning behind having a high fee is to protect against spam and abuse of the bridge.
- 2. Have a non-zero source and destination contract address set.
- 3. No other connector is registered for the local token on the respective chain.
- 4. Its ownership was transferred to the bridge contract address.

We expect this to be mainly done by DAOs or founding teams of popular tokens. It is required to be done once.

Once a registration is done, the bridge will be able to handle the bridging of the token between the two chains and relayers will pick up the state transfers and apply them to the respective chains.

#### Connector registration for a token on TARA <> ETH

![Token Registration Flow](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/Taraxa-project/bridge/master/plantuml/registertoken.iuml)

### Setting up a connector

In the [connectors directory](./src/connectors/), you can find a set of examples for the different types of tokens that can be bridged. For the sake of simplicty, we implemented only connectors for the ERC20 token standard as Ficus bridge will first and foremost serve as a bridge for classic tokens per se.

- 1. Native Connector(s): [They](./src/connectors/NativeConnector.sol) are used to lock and release native tokens on their native chain.
- 2. ERC20 Locking Connector(s): [They](./src/connectors/ERC20LockingConnector.sol) are used to lock and release ERC20 tokens on their respective chain.
- 3. ERC20 Minting Connector(s): [They](./src/connectors/ERC20MintingConnector.sol) are used to burn and mint ERC20 tokens on their respective chain.

## Native Token Bridging

Native asset bridging is a special case that will be one of the main functionalities of the bridge. It allows users to bridge native tokens between the two chains without the necessity of wrapping them first, focusing on the simplest and most effective user experience.

In order to make this happen, besides the classic building blocks, the bridge requires a set of connectors that allow the bridge to interact with the native tokens of each chain.

- 1. Native connector(s): regardless whether we want to bridge ETH or TARA, we need a connector that is able to handle user locks and disbursements.
- 2. ERC20MintingConnector(s): since the native asset of the origin chain doesn't exist on the destination chain, we need a connector that is able to handle the minting of the native asset on the destination chain.
- 3. For this particular reason, we also need to deploy an [ERC20MintableBurnable](./src/lib/TestERC20.sol) ERC20 token on the destination chain that will act as the syntethic version of the native asset on the destination chain. This of it as WTARA in case you want to bridge TARA to ETH.

### Bridging TARA to ETH

![TARA to ETH](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/Taraxa-project/bridge/master/plantuml/taratoeth.iuml)

## ERC20 Token Bridging

Besides Native bridging, simple ERC20 transfers are the other main utility of the bridge. It allows users to bridge any sort of ERC20 from the source chain to the destination chain.

In order to make this happen, besides the classic building blocks, the bridge requires a set of connectors that allow the bridge to interact with the ERC20 tokens of each chain.

- 1. ERC20LockingConnector(s): we need to register a connector that is able to lock the ERC20 tokens on the origin chain and transfer them to the user's accounts when a specific state is applied(ex. when someone bridges back the token that was bridged to the destination chain).
- 2. ERC20MintingConnector(s): since the ERC20 token of the origin chain doesn't exist on the destination chain, we need a connector that is able to handle the minting of the ERC20 token on the destination chain.s
- 3. For this particular reason, we also need to deploy an [ERC20MintableBurnable](./src/lib/TestERC20.sol) ERC20 token on the destination chain that will act as the syntethic version of the ERC20 token on the destination chain.

### Bridging USDT from ETH to TARA

![USDT to TARA](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/Taraxa-project/bridge/master/plantuml/usdttotara.iuml)
