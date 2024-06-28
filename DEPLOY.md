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

### Deployment from ./deployments/.token.deployment.1719603507.json
```json
{
  "tokendeploy-1719603507": {
    "TARA": {
      "address": "0xB37ed9F20ED98343F56D15836b7a2716B0638BDB",
      "RPC": "https://holesky.drpc.org"
    },
    "ETH": {
      "address": "0xdB0698D2c8FbE2C3c36941ccEC488834BbcAf151",
      "RPC": "https://rpc.testnet.taraxa.io"
    }
  }
}
```

### Deployment from ./deployments/.eth.deployment.1719603507.json
```json
{
  "ethdeploy-1719603507": {
    "RPC": "http://127.0.0.1:8545",
    "TaraClient": {
      "implAddress": "0x6BdCf4F809DAA854f3cc177B7e358015D0B8Ff2f",
      "proxyAddress": "0xFA447c6b0E8EEb108E0c9561CdBb2f723Cfd04F4"
    },
    "EthBridge": {
      "implAddress": "0x404e3636652B808A5913CCB50974d7DE06d7728A",
      "proxyAddress": "0xA15d562Ec431892Aa61a7433a0dbc2Ae62c35914"
    },
    "ERC20MintingConnector": {
      "implAddress": "0xdAb8Fd5FD327b95D07F6B9dB85562468A7436b7e",
      "proxyAddress": "0x53fc43657473831aAD2D863BED1E198E4F6181d8"
    },
    "NativeConnector": {
      "implAddress": "0x3059d1055dD49De22Dca30BBC83d7B9FcEfb2c65",
      "proxyAddress": "0xcD07A46204Eb05d9ea791ce37AEa03122e30964a"
    }
  }
}
```

### Deployment from ./deployments/.tara.deployment.1719604246.json
```json
{
  "taradeploy-1719604246": {
    "RPC": "https://rpc.testnet.taraxa.io",
    "BeaconLightClient": "0x3BBdc66Fa7eb51259Da29909529b65232c184519",
    "EthClient": {
      "implAddress": "0xeB372006B243e00d7a97662221D3521be1Fb9a71",
      "proxyAddress": "0x0824335062010047BA9Ca4b4E5b4B35Eb89B972d"
    },
    "TaraBridge": {
      "implAddress": "0x13e6FBcdef48807baFeCA4d55Fd4f0895e34625c",
      "proxyAddress": "0xcAF2b453FE8382a4B8110356DF0508f6d71F22BF"
    },
    "ERC20MintingConnector": {
      "implAddress": "0x305c67850795059a084af6De6E8E3f6422bB4103",
      "proxyAddress": "0x030f4671e48Fc2a0eE4BdA956B2Aba26F5b7F8A9"
    },
    "NativeConnector": {
      "implAddress": "0xaE98B111fFC1452895e4709FE84b7905C8735B69",
      "proxyAddress": "0x98C860E92486975d93A4b83261315c02728Add43"
    }
  }
}
```

