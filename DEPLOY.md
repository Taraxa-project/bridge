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

### Deployment from ./deployments/.eth.deployment.1716392669.json

```json
{
  "ethdeploy-1716392669": {
    "RPC": "https://holesky.drpc.org",
    "TaraClient": {
      "implAddress": "0xc9bbC8b4cf617a231B1bBe3A4b2a9c12d673b604",
      "proxyAddress": "0xA711d06920Fb75C1CD0833cd39987D80Aef69296"
    },
    "EthBridge": {
      "implAddress": "0x672bcEDaCF5dF81241Fe39D7C23A162171B425Bb",
      "proxyAddress": "0x3657dA3a8188Fc389B8c25f466718E272CE824FD"
    },
    "ERC20MintingConnector": {
      "implAddress": "0xc56393d28B10Af5ffBB13b500388B077B0C0A78F",
      "proxyAddress": "0x04D5a6398519CBED0A5b39292B2271b2C5564B8a"
    },
    "NativeConnector": {
      "implAddress": "0x8749e97a8f3c4FE6333fED0F06df42F84FEA2e51",
      "proxyAddress": "0x57751c6181ee22Ec9C402A6bA8ceB44192525988"
    }
  }
}
```

### Deployment from ./deployments/.tara.deployment.1716392789.json

```json
{
  "taradeploy-1716392789": {
    "RPC": "https://rpc-pr-2756.prnet.taraxa.io",
    "BeaconLightClient": {
      "address": "0xa545a5155105844a6c1aF2b4Bc35A09A7ceE6858"
    },
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
