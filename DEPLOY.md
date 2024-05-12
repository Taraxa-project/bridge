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

### 2. Deployment commands

All commands that you need to deploy the bridge are in the `Makefile` but to deploy a symmetric ETH<>TARA bridge the `make bridge-deploy` command will deploy the bridge and the tokens.

```bash
    make bridge-deploy
```

```bash
    make tokens-deploy
    make eth-delpoy
    make tara-deploy
```

These commands will deploy the bridge and the tokens on the respective networks. Each successful deployment will create a `.<component|token|eth|tara>.deployment.<timestamp>.json` file in the root of the project.

Last deployments are stored in the `deployments` folder.

**Note:** The bridge deployment will take some time to complete since we constantly need to rebuild the contracts with the Yul intermediate representation compilation pipeline.

**Note:** The deployment details section below lists both the RPC and the contract addresses for the deployed contracts. To interact with the contracts in Remix or any other tool, you will need to use the proxy addresses as `TaraBridge bridge = TaraBridge(proxyAddress)` or `TaraBridge bridge = TaraBridge(0xFA7c27D54B6e1C631D1426f3dDaC818Cb4033d84)`.

## Deployment Details

### Deployment from ./deployments/.tara.deployment.1715528731.json

```json
{
  "taradeploy-1715528731": {
    "RPC": "https://rpc-pr-2618.prnet.taraxa.io",
    "EthClient": {
      "implAddress": "0x0BB682a37FAA58Ed701283ff09aF4937BB5C618B",
      "proxyAddress": "0xd16E9610A109118caD605F370025b51B78eaE988"
    },
    "TaraBridge": {
      "implAddress": "0xFBC597EEf68722E05bbC1e52264103b416551dFB",
      "proxyAddress": "0xFA7c27D54B6e1C631D1426f3dDaC818Cb4033d84"
    },
    "ERC20MintingConnector": {
      "implAddress": "0x76C7c6eD590ddC9E8d71377c4Eb1386A83330DF3",
      "proxyAddress": "0xf014b0A09A9de4311ca62Af7654299be1337C5E8"
    },
    "NativeConnector": {
      "implAddress": "0xf3cB9a75dC647531A18cB0fbA78e08d5604846AA",
      "proxyAddress": "0x2D76E86F8285873Ba16EDCa529c884DE3661e62F"
    }
  }
}
```

### Deployment from ./deployments/.eth.deployment.1715528385.json

```json
{
  "ethdeploy-1715528385": {
    "RPC": "https://holesky.drpc.org",
    "TaraClient": {
      "implAddress": "0x402908C007aAC2fAf83D57945ff95cF2de49b359",
      "proxyAddress": "0x515d5e39a9FfF8dBBD84C8064ea3Bc4ad2610442"
    },
    "EthBridge": {
      "implAddress": "0x762dA247D9F269b1689d4baaD587243eccF7910c",
      "proxyAddress": "0x438623c79b1721f13666a844F6Bc78619031ACd6"
    },
    "ERC20MintingConnector": {
      "implAddress": "0xd1FA7C5782cc53dA98fC444c1A148338547Af763",
      "proxyAddress": "0x604AF5F90acAC6bF459b5337002152dDd17c1e88"
    },
    "NativeConnector": {
      "implAddress": "0xb1ADA9687f03D7fBE3756037E32FB27d2185f60D",
      "proxyAddress": "0x575E6706Acfab1e3A17daa8692b90Bd62D9c4674"
    }
  }
}
```

### Deployment from ./deployments/.token.deployment.1715527980.json

```json
{
  "tokendeploy-1715527980": {
    "TARA": {
      "implAddress": "0x3f810D69D2D6C4E7150743e8b1170761d0d905Ae",
      "proxyAddress": "0x7E7921cb1440E76c1D4a59F9996e65e9a5B8761c",
      "RPC": "https://holesky.drpc.org"
    },
    "ETH": {
      "implAddress": "0x1d7FC09d70cEc88e7a048B84A80D381d92dbDBFF",
      "proxyAddress": "0x8271649B4a682603119E118f250DCFde455B3286",
      "RPC": "https://rpc-pr-2618.prnet.taraxa.io"
    }
  }
}
```
