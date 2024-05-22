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

### Deployment from ./deployments/.token.deployment.1716392426.json

```json
{
  "tokendeploy-1716392426": {
    "TARA": {
      "address": "0x50Abd4a0B59Bcbfe9ee75E3cB8c1de006CE0f531",
      "RPC": "https://holesky.drpc.org"
    },
    "ETH": {
      "address": "0xf798c0dAa637088b3e4C5ae88A20551c17438ee5",
      "RPC": "https://rpc-pr-2756.prnet.taraxa.io"
    }
  }
}
```

### Deployment from ./deployments/.tara.deployment.1716392789.json

```json
{
  "taradeploy-1716392789": {
    "RPC": "https://rpc-pr-2756.prnet.taraxa.io",
    "EthClient": {
      "implAddress": "0x25394E29b8DFf642e66B221217AF7D313340C1fA",
      "proxyAddress": "0xf6F70aD8212105bd51695766153793Cf9AE94F78"
    },
    "TaraBridge": {
      "implAddress": "0x3Afa48FcF6191e0589CB2EED55820118aFB80A1e",
      "proxyAddress": "0xd2C5ccAa72bfaF2d28e8e924D77870eBab3d047f"
    },
    "ERC20MintingConnector": {
      "implAddress": "0x86Ba9aB2c10EbE0E025C141a74d0A5A7016E8304",
      "proxyAddress": "0xC2073b2319588d2245493Fd03BAdBECb05288c16"
    },
    "NativeConnector": {
      "implAddress": "0xe90BEbE643526FE85131bBfc4d12b1Eef9dd283C",
      "proxyAddress": "0x72129D8648570ED5719AD49Ff4D51b28d47b59bB"
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
