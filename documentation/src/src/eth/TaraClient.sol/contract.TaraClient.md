# TaraClient
[Git Source](https://github.com-VargaElod23/Taraxa-project/bridge/blob/996f61a29d91a8326c805bfdad924088129ae1a7/src/eth/TaraClient.sol)

**Inherits:**
[IBridgeLightClient](/src/lib/IBridgeLightClient.sol/interface.IBridgeLightClient.md), OwnableUpgradeable


## State Variables
### finalized

```solidity
PillarBlock.FinalizedBlock public finalized;
```


### validatorVoteCounts

```solidity
mapping(address => uint256) public validatorVoteCounts;
```


### totalWeight

```solidity
uint256 public totalWeight;
```


### threshold

```solidity
uint256 public threshold;
```


### pillarBlockInterval

```solidity
uint256 public pillarBlockInterval;
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
function initialize(uint256 _threshold, uint256 _pillarBlockInterval) public initializer;
```

### __TaraClient_init_unchained


```solidity
function __TaraClient_init_unchained(uint256 _threshold, uint256 _pillarBlockInterval) internal onlyInitializing;
```

### getFinalized


```solidity
function getFinalized() public view returns (PillarBlock.FinalizedBlock memory);
```

### getFinalizedBridgeRoot

*Returns the finalized bridge root.*


```solidity
function getFinalizedBridgeRoot() external view returns (bytes32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|The finalized bridge root as a bytes32 value.|


### setThreshold

*Sets the vote weight threshold value.*


```solidity
function setThreshold(uint256 _threshold) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_threshold`|`uint256`|The new threshold value to be set.|


### processValidatorChanges

*Processes the changes in validator weights.*


```solidity
function processValidatorChanges(PillarBlock.VoteCountChange[] memory validatorChanges) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`validatorChanges`|`PillarBlock.VoteCountChange[]`|An array of VoteCountChange structs representing the changes in validator vote counts.|


### finalizeBlocks

*Pinalizes blocks by verifying the signatures for the last blocks*


```solidity
function finalizeBlocks(PillarBlock.WithChanges[] memory blocks, CompactSignature[] memory lastBlockSigs) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`blocks`|`PillarBlock.WithChanges[]`|list of PillarBlockWithChanges.|
|`lastBlockSigs`|`CompactSignature[]`|An array of Signature structs representing the signatures of the last block.|


### getSignaturesWeight

*Calculates the total weight of the signatures*


```solidity
function getSignaturesWeight(bytes32 h, CompactSignature[] memory signatures) public view returns (uint256 weight);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`h`|`bytes32`|The hash for verification.|
|`signatures`|`CompactSignature[]`|An array of signatures.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`weight`|`uint256`|The total weight of the signatures.|


## Events
### Initialized
Events


```solidity
event Initialized(uint256 threshold, uint256 pillarBlockInterval);
```

### ThresholdChanged

```solidity
event ThresholdChanged(uint256 threshold);
```

### ValidatorWeightChanged

```solidity
event ValidatorWeightChanged(address indexed validator, uint256 weight);
```

### BlockFinalized

```solidity
event BlockFinalized(PillarBlock.FinalizedBlock finalized);
```

