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

### 2. Deploy ETH & TARA tokens on both sides

```bash
    make tokens-deploy
```

For more details check the [Tokens deployment script](./src/scripts/tokensDeploy.sh) or the [Forge script](./src/scripts/Token.deploy.s.sol).

### 2. Deploy the ETH side of the bridge & TARA token

There are two scripts to do this:

```bash
    make eth-deploy
```

This will deploy the ETH side of the bridge and output the contract addresses.

The latest token deployment addresses are:

```bash
  ETH token address on Taraxa PRNET 2618:
  0xcb451533b59783c144466da821901F61d8AEC6b6.
  Tara token address on ETH Holesky:
  0x58B72519c404b3Bf8e2F3105Fd4A8d38beAC0b76.
```

#### 2.1 Holesky Deployment

```bash
  Deployer address:
  0x602EFf175fcC46936563BB7A9C4F257De2fc5421
  TARA token address on Holesky:
  0x58B72519c404b3Bf8e2F3105Fd4A8d38beAC0b76
  TaraClient proxy address:
  0xF7d9b60Bc676cFa90281C8c30798D16c37579aA2
  EthBridge proxy address:
  0x2B666e1354159f9128407c4269a8b70d66f4bDe8
  ERC20MintingConnector proxy address:
  0xe66cA4F0Fd205A20c577474D8FD3F315f75f6B99

```

### Deploy Tara side of the bridge

```bash
    make tara-deploy
```

This will deploy the TARA side of the bridge and output the contract addresses.

#### 3.1 Tara Deployment

```bash
    == Logs ==
  Deployer address:
  0x602EFf175fcC46936563BB7A9C4F257De2fc5421
  BeaconLightClient address:
  0xE6f0E4A7Ac8F1801FfAf6BF5F658d732388D10Ef
  ETHClient address:
  0xE42C12c129ba10C5394d73801840F551AE6a7B1c
  TARABridge address:
  0x7E7921cb1440E76c1D4a59F9996e65e9a5B8761c
  Tara(NativeConnector) address:
  0x515d5e39a9FfF8dBBD84C8064ea3Bc4ad2610442
```
