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
    TARA address: 0xe01095F5f61211b2daF395E947C3dA78D7a431Ab
    Bridge address: 0xeeaC5d17458E3AAABaC2D818e33490CC42c83d8C
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
  Client address: 0x83BA75e668B479376973F4C7B0D240E4b5B25237
  ETH address: 0xe01095F5f61211b2daF395E947C3dA78D7a431Ab
  TARA Bridge address: 0x98edEa58C0500287B973348ec315f3d26D0e189A
  Wrapper address: 0xa0ACAa383Aa22Eb0C93b115344C05409BBBE68d6
```
