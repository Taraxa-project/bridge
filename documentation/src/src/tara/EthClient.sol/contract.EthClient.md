# EthClient
[Git Source](https://github.com-VargaElod23/Taraxa-project/bridge/blob/996f61a29d91a8326c805bfdad924088129ae1a7/src/tara/EthClient.sol)

**Inherits:**
[IBridgeLightClient](/src/lib/IBridgeLightClient.sol/interface.IBridgeLightClient.md), OwnableUpgradeable


## State Variables
### client

```solidity
BeaconLightClient public client;
```


### ethBridgeAddress

```solidity
address public ethBridgeAddress;
```


### bridgeRootKey

```solidity
bytes32 public bridgeRootKey;
```


### bridgeRoot

```solidity
bytes32 bridgeRoot;
```


### refund

```solidity
uint256 refund;
```


### __gap
gap for upgrade safety <- can be used to add new storage variables(using up to 49  32 byte slots) in new versions of this contract
If used, decrease the number of slots in the next contract that inherits this one(ex. uint256[48] __gap;)


```solidity
uint256[49] __gap;
```


## Functions
### initialize


```solidity
function initialize(BeaconLightClient _client, address _eth_bridge_address) public initializer;
```

### getFinalizedBridgeRoot

*Implements the IBridgeLightClient interface method*


```solidity
function getFinalizedBridgeRoot() external view returns (bytes32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|The finalized bridge root as a bytes32 value.|


### refundAmount


```solidity
function refundAmount() external view returns (uint256);
```

### processBridgeRoot

*Processes the bridge root by verifying account and storage proofs against state root from the light client.*


```solidity
function processBridgeRoot(bytes[] memory account_proof, bytes[] memory storage_proof) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account_proof`|`bytes[]`|The account proofs for the bridge root.|
|`storage_proof`|`bytes[]`|The storage proofs for the bridge root.|


### getMerkleRoot

*Returns the Merkle root from the light client.*


```solidity
function getMerkleRoot() external view returns (bytes32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|The Merkle root as a bytes32 value.|


## Events
### Initialized
Events


```solidity
event Initialized(address indexed client, address indexed ethBridgeAddress);
```

### BridgeRootProcessed

```solidity
event BridgeRootProcessed(bytes32 indexed bridgeRoot);
```

