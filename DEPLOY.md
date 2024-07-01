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
  "tokendeploy-1719841164": {
    "TARA": {
      "address": "0x6d13fbC0E1D86C2A6e99d2E61582981Ab77B8737",
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
  "ethdeploy-1719841807": {
    "RPC": "https://holesky.drpc.org",
    "TaraClient": {
      "implAddress": "0xFbe6471D41b6daC926a0c894cb2Ef4E0dDd11147",
      "proxyAddress": "0x68bb3555Dc111095f0678bBA4fF0A01aeA362eA1"
    },
    "EthBridge": {
      "implAddress": "0x68164775E80D46E9bf80367C588E67ea38eCCcAE",
      "proxyAddress": "0xef0541F2255F7621A3AFf56D8732eE02BC9dACed"
    },
    "ERC20MintingConnector": {
      "implAddress": "0xE519805ACE4F4D839efB6AF9a165FEB7f34500D7",
      "proxyAddress": "0x733E769d6E949caD4377d3496791D20aC54D2Cd1"
    },
    "NativeConnector": {
      "implAddress": "0x694Aaced0945Be71A1eDa958a09fcf44999384dE",
      "proxyAddress": "0x2236a5ac653BBc653430Ce0920c61273BB1eA76B"
    }
  }
}
```

### Deployment from ./deployments/.tara.deployment.1719604246.json

```json
{
  "taradeploy-1719841927": {
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
