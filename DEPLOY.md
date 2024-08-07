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

### Deployment from ./deployments/.token.deployment.1723033705.json
```json
{
  "tokendeploy-1723033705": {
    "TARA": {
      "address": "0x2F42b7d686ca3EffC69778B6ED8493A7787b4d6E",
      "RPC": "https://mainnet.infura.io"
    },
    "ETH": {
      "address": "0x39b1fC930C43606af5C353e90a55db10bCaF4087",
      "RPC": "https://rpc.mainnet.taraxa.io"
    }
  }
}
```

### Deployment from ./deployments/.eth.deployment.1723033705.json
```json
{
  "ethdeploy-1723033705": {
    "RPC": "https://mainnet.infura.io",
    "TaraClient": {
      "implAddress": "0x9732044c8AF3C96382Ba5D4252ae2f99ad18BcA6",
      "proxyAddress": "0xcDF14446F78ea7EBCaa62Fdb0584e4D2e536B999"
    },
    "EthBridge": {
      "implAddress": "0x5c3031a020a067Aeb238cBe29Db6caD992F10Dc3",
      "proxyAddress": "0x359CF536b1fd6248ebAd1449E1B3727caB33A01d"
    },
    "ERC20MintingConnector": {
      "implAddress": "0xa134A9513589FA446F0A4Da548A18488E38729B1",
      "proxyAddress": "0xfF235eA751964bBA3887392dE889a834A2Bdfbde"
    },
    "NativeConnector": {
      "implAddress": "0x87c7Aaa50fa200c6c26B37B7C31C3e996B0B85D1",
      "proxyAddress": "0x2B5eC5C4A513eB21d49449d09e2B0c75CEbE51dA"
    }
  }
}
```

### Deployment from ./deployments/.tara.deployment.1723033705.json
```json
{
  "taradeploy-1723033705": {
    "RPC": "https://rpc.mainnet.taraxa.io",
    "BeaconLightClient": "0x97Eb8E024bE036eCdb25aDf842C5D6241189FB53",
    "EthClient": {
      "implAddress": "0x0F75f4870D1981Be80525C84DAfD2d20fc29DebF",
      "proxyAddress": "0x7157233800c3c1f2ac8b12Cefe2cBE796C04446B"
    },
    "TaraBridge": {
      "implAddress": "0x8eB23BA07aadB69C44E67e901BfC0Ec516B490d1",
      "proxyAddress": "0xe126E0BaeAE904b8Cfd619Be1A8667A173b763a1"
    },
    "ERC20MintingConnector": {
      "implAddress": "0x59619AD0c271eb7609102ba79Cb1A359f52657da",
      "proxyAddress": "0xD014293ED981c7f557C0Cf55F7FbA025082Ed266"
    },
    "NativeConnector": {
      "implAddress": "0x5d58590B00854253b6996EC4Be6696E6d4A12A29",
      "proxyAddress": "0x7C5E17A43c6cb223a86C5d63288273E0c1F1283F"
    }
  }
}
```

