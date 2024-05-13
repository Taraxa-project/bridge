# This document serves as an integration manual for the most popular flows the Bridge is able to support

## Use cases

### Deployments

This document will list only the deployment addresses that are required for the flows. For more detailed information consult the [deployment document](DEPLOY.md) or the [ETH deployment script](scripts/Eth.deploy.sol) and [Tara deployment script](scripts/Tara.deploy.sol).

### Transfer Tara from Taraxa to ETH

#### Requirements - Taraxa

- Tara Connector deployed on Taraxa: `0x9E2762b1ef4F7Cc00BE66e024D5Db5E8dfB0BD6C`
- ERC20 Minting Connector deployed on ETH: `0xD4fa020c9318d5fc1F57b1551C9f507a967dEa61`
- WTARA on ETH: `0x3E02bDF20b8aFb2fF8EA73ef5419679722955074`

#### Steps - Taraxa

1. Lock in Tara on the Taraxa Connector via calling [the lock function with your desired value](./src/tara/TaraConnector.sol#L42). Emits a `Locked` event with the origin `account` and `value` locked.
2. Wait until the epoch is finalized and the bridge root & state is applied on the ETH side.
3. Get the exact fee you need to pay to claim on the ETH side via calling [the feeToClaim view function with your address](./src/connectors/BridgeConnectorBase.sol#L12).
4. Claim on the ETH side via calling [the claim function with the claim fee](./src/connectors/ERC20MintingConnector.sol#L52). Emits a `Claimed` event with the origin `account` and `value` claimed.

The relevant test case is [here](./test/StateTransfers.t.sol#L93).

### Transfer ETH from ETH to Taraxa

#### Requirements - ETH

- ETH ERC20MintingConnector deployed on ETH: `0xD4fa020c9318d5fc1F57b1551C9f507a967dEa61`.
- WTARA deployed on ETH: `0x3E02bDF20b8aFb2fF8EA73ef5419679722955074`.
- ETHBridge deployed on ETH: `0x5D126cB4E9f78145881762e2f62e5ce1C35B787f`.
- ETH Light client deployed on Taraxa: `0x686244563F8785C383da55df9872b23be3f9acf8`.
- Taraxa Bridge deployed on Taraxa: `0x07fdD5b6fe9BD40d5ECDb90A6b039B4A24b929DA`.
- TaraConnector deployed on Taraxa: `0x9E2762b1ef4F7Cc00BE66e024D5Db5E8dfB0BD6C`.

#### Steps - ETH

1. Burn ERC20 WTARA on ETH via calling [the burn function with your desired value](./src/connectors/ERC20MintingConnector.sol#L47). Emits a `Burned` event with the origin `account` and `value` burned.
2. Wait until the epoch is finalized and the bridge root & state is applied on the Taraxa side.
3. Get the exact fee you need to pay to claim via on the TARA side calling [the feeToClaim view function with your address](./src/connectors/BridgeConnectorBase.sol#L12).
4. Claim on the Taraxa side via calling [the claim function with the claim fee](./src/tara/TaraConnector.sol#L52). Emits a `Claimed` event with the origin `account` and `value` claimed.

The relevant test case is [here](./test/StateTransfers.t.sol#L112).

### Transfer DOGE from ETH to Taraxa

1. Register & deploy the DOGE token into the ETH ERC20LockingConnector like [here](./test/StateTransfers.t.sol#L258).
2. Deploy WDOGE and the respective ERC20MintingConnector on TARA side like [here](./test/StateTransfers.t.sol#L260).
3. Register the TARA side of the setup with the TARA Bridge like [here](./test/StateTransfers.t.sol#L273).
4. Register the ETH side of the setup with the ETH Bridge like [here](./test/StateTransfers.t.sol#L274).
5. Lock some DOGE into the ETH ERC20LockingConnector like [here](./test/StateTransfers.t.sol#L278).
6. Wait until the epoch is finalized and the bridge root & state is applied on the Taraxa side.
7. Get the exact fee you need to pay to claim via on the TARA side calling [the feeToClaim view function with your address](./src/connectors/BridgeConnectorBase.sol#L12).
8. Claim on the Taraxa side via calling [the claim function with the claim fee](./src/tara/TaraConnector.sol#L52). Emits a `Claimed` event with the origin `account` and `value` claimed.

The relevant test case is [here](./test/StateTransfers.t.sol#L252). The test case describes the opposite flow whereas DOGE is created on the TARA side, transferred to the ETH side and then transferred back to the TARA side in the following [test case](./test/StateTransfers.t.sol#L335).
