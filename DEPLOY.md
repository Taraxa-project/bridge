# Deployment Glossary

The sample bridge will be deployed on Holesky testnet. The bridge will be deployed in two parts, one on the Ethereum side and the other on the Tara side, to a specific Ficus-hf PRnet.

## Ficus-hf RPC details

```bash
RPC https://rpc-pr-2618.prnet.taraxa.io
```

## Holesky RPC details

```bash
RPC https://holesky.drpc.org
```

## Steps to deploy the bridge

### Get the last known working foundry niglty build that works with Taraxa networks - we're working on this and hope to have a more stable solution soon

```bash
    make get-foundry
```

### 1. Get Holesky ETH

[Holesky Faucet](https://stakely.io/en/faucet/ethereum-holesky-testnet-eth)

The sample deployment address used is `0x602EFf175fcC46936563BB7A9C4F257De2fc5421`.

### 2. Deploy the ETH side of the bridge & TARA token

There are two scripts to do this:

```bash
    make eth-deploy
```

This will deploy the ETH side of the bridge and output the contract addresses. However, for some reason, sometimes it does error out. In that case, you can deploy the contracts manually via:

```bash
    forge script scripts/Eth.deploy.sol:EthDeployer --via-ir --rpc-url https://holesky.drpc.org  --broadcast --legacy
```

#### 2.1 Holesky Deployment

```bash
    Deployer address: 0x602EFf175fcC46936563BB7A9C4F257De2fc5421
    TARA address: 0x3E02bDF20b8aFb2fF8EA73ef5419679722955074
    Bridge address: 0x5D126cB4E9f78145881762e2f62e5ce1C35B787f
    ERC20MintingConnector: https://holesky.etherscan.io/address/0xD4fa020c9318d5fc1F57b1551C9f507a967dEa61
    TaraClient: https://holesky.etherscan.io/address/0xA14bd7A4b016Eb315656Dfbd7BB7f97Af67ed1d6

```

### Deploy Tara side of the bridge

```bash
    make tara-deploy
```

This will deploy the TARA side of the bridge and output the contract addresses. However, for some reason, sometimes it does error out. In that case, you can deploy the contracts manually via:

```bash
    forge script src/scripts/Tara.deploy.s.sol:TaraDeployer --via-ir --rpc-url https://rpc-pr-2618.prnet.taraxa.io --legacy --broadcast
```

#### 3.1 Tara Deployment

```bash
    == Logs ==
  Deployer address: 0x602EFf175fcC46936563BB7A9C4F257De2fc5421
  BeaconLightClient address: 0x58B72519c404b3Bf8e2F3105Fd4A8d38beAC0b76
  ETHClient address: 0x686244563F8785C383da55df9872b23be3f9acf8
  TARABridge address: 0x07fdD5b6fe9BD40d5ECDb90A6b039B4A24b929DA
  TaraConnector address: 0x9E2762b1ef4F7Cc00BE66e024D5Db5E8dfB0BD6C
  Wrapper address: 0xa0ACAa383Aa22Eb0C93b115344C05409BBBE68d6
```
