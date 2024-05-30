# EthClient
[Git Source](https://github.com/Taraxa-project/bridge/blob/e4d318b451d9170f9f2dde80fe4263043786ba03/src/tara/EthClient.sol)

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
### constructor


```solidity
constructor();
```

### initialize


```solidity
function initialize(BeaconLightClient _client, address _eth_bridge_address) public initializer;
```

### getFinalizedBridgeRoot

*Implements the IBridgeLightClient interface method*


```solidity
function getFinalizedBridgeRoot(uint256 epoch) external view returns (bytes32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|The finalized bridge root as a bytes32 value.|


### processBridgeRoot

*Processes the bridge root by verifying account and storage proofs against state root from the light client.*


```solidity
function processBridgeRoot(uint256 block_number, bytes[] memory account_proof, bytes[] memory storage_proof) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`block_number`|`uint256`||
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
### BridgeRootProcessed
Events


```solidity
event BridgeRootProcessed(bytes32 indexed bridgeRoot);
```

