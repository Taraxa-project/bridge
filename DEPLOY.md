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

### Deployment from ./deployments/.eth.deployment.1718221533.json
```json
{
  "ethdeploy-1718221533": {
    "RPC": "https://holesky.infura.io/v3/3cd3fc92a35c4816b43d752cd947bbab",
    "TaraClient": {
      "implAddress": "0xF94D4e3e4D9772198C141A7dd15895775ED57137",
      "proxyAddress": "0xa4500EC54Af1997e5D1f8Ef4AD2326C75D83Bdf5"
    },
    "EthBridge": {
      "implAddress": "0xE6C0e029cC6b8166f4da78a7B08597e565C1C58d",
      "proxyAddress": "0xfc4B70A15fAce3C8df3b4C6eDF9cb07d7f65CE12"
    },
    "ERC20MintingConnector": {
      "implAddress": "0xD98D0dF89D166e5C2Fb1Fbfc2e58071eF53d3EBD",
      "proxyAddress": "0x3d3453d1f2b1157690964C02199a30b471dB179C"
    },
    "NativeConnector": {
      "implAddress": "0x1690d8626E4Ab8e1Ae11f6C1230c3b8a0DBAf30c",
      "proxyAddress": "0xFD4294531bc0dAb56566968c7523e8982525700D"
    }
  }
}
```

### Deployment from ./deployments/.token.deployment.1718220637.json
```json
{
  "tokendeploy-1718220637": {
    "TARA": {
      "address": "0x24d8a7D969c1b4A3A5a784b127A893Ecfa84263C",
      "RPC": "https://holesky.drpc.org"
    },
    "ETH": {
      "address": "0xdB0698D2c8FbE2C3c36941ccEC488834BbcAf151",
      "RPC": "https://rpc.devnet.taraxa.io"
    }
  }
}
```

### Deployment from ./deployments/.tara.deployment.1718221640.json
```json
{
  "taradeploy-1718221640": {
    "RPC": "https://rpc.devnet.taraxa.io",
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

