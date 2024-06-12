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

### Deployment from ./deployments/.token.deployment.1717091029.json
```json
{
  "tokendeploy-1717091029": {
    "TARA": {
      "address": "0x09A77e9b4a8E96Fe874A88229a95BC69Bc2e05F9",
      "RPC": "https://holesky.drpc.org"
    },
    "ETH": {
      "address": "0xdB0698D2c8FbE2C3c36941ccEC488834BbcAf151",
      "RPC": "https://rpc-pr-2618.prnet.taraxa.io"
    }
  }
}
```

### Deployment from ./deployments/.tara.deployment.1717091205.json
```json
{
  "taradeploy-1717091205": {
    "RPC": "https://rpc-pr-2618.prnet.taraxa.io",
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

### Deployment from ./deployments/.eth.deployment.1717091129.json
```json
{
  "ethdeploy-1717091129": {
    "RPC": "https://holesky.drpc.org",
    "TaraClient": {
      "implAddress": "0x1D1E2e435CEba04C9209FE6Ea1BaaE4D90a59469",
      "proxyAddress": "0x041cf5DC73793483e638Ae6333B348bbe42b96dE"
    },
    "EthBridge": {
      "implAddress": "0x513FfdbE5b2f6Bf2cb8116a16B9375fd20550622",
      "proxyAddress": "0xe67957f965b3cb5c58abF0309D9a8e98787Ab75e"
    },
    "ERC20MintingConnector": {
      "implAddress": "0xE0bcaC3b12cd64d25E52d921a79e53421AD6E0a2",
      "proxyAddress": "0x6aA8f4644bAa008e1fD6A81d31aCCC1cCf13e339"
    },
    "NativeConnector": {
      "implAddress": "0x6FdE52E45acd76541Cc7Aae036358329f000DF59",
      "proxyAddress": "0x6B404ccd2AEa5B06F00a4f3565fE88Ed1fD7A07E"
    }
  }
}
```

## Deployment Details

### Deployment from ./deployments/.token.deployment.1716544892.json
```json
{
  "tokendeploy-1716544892": {
    "TARA": {
      "address": "0x72862dc8eB9251D3ABE9cba411c41b38A9Ed12C9",
      "RPC": "https://holesky.drpc.org"
    },
    "ETH": {
      "address": "0xdB0698D2c8FbE2C3c36941ccEC488834BbcAf151",
      "RPC": "https://rpc-pr-2756.prnet.taraxa.io"
    }
  }
}
```

### Deployment from ./deployments/.eth.deployment.1716545201.json
```json
{
  "ethdeploy-1716545201": {
    "RPC": "https://holesky.drpc.org",
    "TaraClient": {
      "implAddress": "0xd3EAF83f1984308633E1bB26a8DA49bA0658e587",
      "proxyAddress": "0xFEBFE005CfeBC59590C7f22b61C13a296AF01f49"
    },
    "EthBridge": {
      "implAddress": "0x06BBa509ca36e9f764f94b9Ce8420b424fD94015",
      "proxyAddress": "0x7744121681C9D9Bd1fA8aff148Cffe98b5E152e8"
    },
    "ERC20MintingConnector": {
      "implAddress": "0xA190Db338F1838bDfD13E8b2d6F4505EFf002B0F",
      "proxyAddress": "0xA23C7dF2E9fa24D1F20Ead92D49fad012d7B3A42"
    },
    "NativeConnector": {
      "implAddress": "0x937450589aAB8A807310e493fE51f70bC65cC053",
      "proxyAddress": "0x78410949dDEEEbfAf7527f95d873c84297F82618"
    }
  }
}
```

### Deployment from ./deployments/.token.deployment.1717091029.json
```json
{
  "tokendeploy-1717091029": {
    "TARA": {
      "address": "0x09A77e9b4a8E96Fe874A88229a95BC69Bc2e05F9",
      "RPC": "https://holesky.drpc.org"
    },
    "ETH": {
      "address": "0xdB0698D2c8FbE2C3c36941ccEC488834BbcAf151",
      "RPC": "https://rpc-pr-2618.prnet.taraxa.io"
    }
  }
}
```

### Deployment from ./deployments/.tara.deployment.1718103360.json
```json
{
  "taradeploy-1718103360": {
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

### Deployment from ./deployments/.token.deployment.1718102752.json
```json
{
  "tokendeploy-1718102752": {
    "TARA": {
      "address": "0x67097749cbD3969D26313287C9DaF87Fca9b88F1",
      "RPC": "https://holesky.drpc.org"
    },
    "ETH": {
      "address": "0xdB0698D2c8FbE2C3c36941ccEC488834BbcAf151",
      "RPC": "https://rpc.devnet.taraxa.io"
    }
  }
}
```

### Deployment from ./deployments/.doge.deployment.1716828959.json
```json
{
  "dogedeploy-1716828959": {
    "RPC_ETH": "https://holesky.drpc.org",
    "RPC_TARA": "https://rpc-pr-2756.prnet.taraxa.io",
    "DOGE": {
      "address": "0xb8ca5447C1850A6dC4f5b0c8a1a5F8c040C41B76",
      "syntheticAddress": "0xFEBFE005CfeBC59590C7f22b61C13a296AF01f49"
    },
    "DOGE_CONNECTOR_ETH": {
      "implAddress": "0x78410949dDEEEbfAf7527f95d873c84297F82618",
      "proxyAddress": "0x9814b171aCa172B7a7ABDdDa6a42c0aCCa8fBABb"
    },
    "DOGE_CONNECTOR_TARA": {
      "implAddress": "0x78410949dDEEEbfAf7527f95d873c84297F82618",
      "proxyAddress": "0x9814b171aCa172B7a7ABDdDa6a42c0aCCa8fBABb"
    }
  }
}
```

### Deployment from ./deployments/.tara.deployment.1717091205.json
```json
{
  "taradeploy-1717091205": {
    "RPC": "https://rpc-pr-2618.prnet.taraxa.io",
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

### Deployment from ./deployments/.tara.deployment.1716545354.json
```json
{
  "taradeploy-1716545354": {
    "RPC": "https://rpc-pr-2756.prnet.taraxa.io",
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

### Deployment from ./deployments/.eth.deployment.1718102825.json
```json
{
  "ethdeploy-1718102825": {
    "RPC": "https://holesky.drpc.org",
    "TaraClient": {
      "implAddress": "0xB7f443e3c057a86B72E1574dD211C9472C28e2eb",
      "proxyAddress": "0x0247aea1463d9B128826711951Ce0da3253dEB4A"
    },
    "EthBridge": {
      "implAddress": "0x79Fb265371E736d1B5c6B40A1d4Dc0dc189faA42",
      "proxyAddress": "0xf4ca7db548013f7325A7d9c1C3bBD185C9f4267E"
    },
    "ERC20MintingConnector": {
      "implAddress": "0xf461160377e7DE309F116fD4446c964e6A68FA45",
      "proxyAddress": "0x1f6Db7356F2234058414Dc49d51095BBd1c31923"
    },
    "NativeConnector": {
      "implAddress": "0xc3b31fAE5f91ce2c3b6d3D66800803983937ebCe",
      "proxyAddress": "0xd62A3E1F0b48119FB6981B7e9232A31D1Fb1c99b"
    }
  }
}
```

### Deployment from ./deployments/.eth.deployment.1717091129.json
```json
{
  "ethdeploy-1717091129": {
    "RPC": "https://holesky.drpc.org",
    "TaraClient": {
      "implAddress": "0x1D1E2e435CEba04C9209FE6Ea1BaaE4D90a59469",
      "proxyAddress": "0x041cf5DC73793483e638Ae6333B348bbe42b96dE"
    },
    "EthBridge": {
      "implAddress": "0x513FfdbE5b2f6Bf2cb8116a16B9375fd20550622",
      "proxyAddress": "0xe67957f965b3cb5c58abF0309D9a8e98787Ab75e"
    },
    "ERC20MintingConnector": {
      "implAddress": "0xE0bcaC3b12cd64d25E52d921a79e53421AD6E0a2",
      "proxyAddress": "0x6aA8f4644bAa008e1fD6A81d31aCCC1cCf13e339"
    },
    "NativeConnector": {
      "implAddress": "0x6FdE52E45acd76541Cc7Aae036358329f000DF59",
      "proxyAddress": "0x6B404ccd2AEa5B06F00a4f3565fE88Ed1fD7A07E"
    }
  }
}
```

