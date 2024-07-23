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
    make eth-deploy
    make tara-deploy
```

These commands will deploy the bridge and the tokens on the respective networks. Each successful deployment will create a `.<component|token|eth|tara>.deployment.<timestamp>.json` file in the root of the project.

Last deployments are stored in the `deployments` folder.

**Note:** The bridge deployment will take some time to complete since we constantly need to rebuild the contracts with the Yul intermediate representation compilation pipeline.

**Note:** The deployment details section below lists both the RPC and the contract addresses for the deployed contracts. To interact with the contracts in Remix or any other tool, you will need to use the proxy addresses as `TaraBridge bridge = TaraBridge(proxyAddress)` or `TaraBridge bridge = TaraBridge(0xFA7c27D54B6e1C631D1426f3dDaC818Cb4033d84)`.

## Deployment Details

### Deployment from ./deployments/.eth.deployment.1721744738.json
```json
{
  "ethdeploy-1721744738": {
    "RPC": "http://127.0.0.1:8545",
    "TaraClient": {
      "implAddress": "0x1833FC66B62Ac041792010F2ab5Ec286CeA7268D",
      "proxyAddress": "0x81f2A5BEB025461F8F4ed88Db1a37C642C3D769A"
    },
    "EthBridge": {
      "implAddress": "0x443E0B28A9f74c79B969B29560929558E1bC6113",
      "proxyAddress": "0x19934742B3EC8e647Bfd0fB4f3e39630d44a4978"
    },
    "ERC20MintingConnector": {
      "implAddress": "0x1bcFE19B3e0AC93fBc28676b2D5cFc6E5a018fDF",
      "proxyAddress": "0x65562b866d50FEb5f9CE282c1D09d49e4897a5b0"
    },
    "NativeConnector": {
      "implAddress": "0x55d5AD3F575f145a73bD46649b8D24344b6c803C",
      "proxyAddress": "0xaA7c342CFA5AaB0edd4e2d66C33E7DB42E633230"
    }
  }
}
```

### Deployment from ./deployments/.token.deployment.1721744562.json
```json
{
  "tokendeploy-1721744562": {
    "TARA": {
      "address": "0x7E6676e36D60B187fF8453Fa0D53F6f0CBCf358B",
      "RPC": "http://127.0.0.1:8545"
    },
    "ETH": {
      "address": "0xdB0698D2c8FbE2C3c36941ccEC488834BbcAf151",
      "RPC": "https://rpc.testnet.taraxa.io"
    }
  }
}
```

### Deployment from ./deployments/.tara.deployment.1721744970.json
```json
{
  "taradeploy-1721744970": {
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

