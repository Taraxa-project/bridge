# BridgeBase
[Git Source](https://github.com-VargaElod23/Taraxa-project/bridge/blob/996f61a29d91a8326c805bfdad924088129ae1a7/src/lib/BridgeBase.sol)

**Inherits:**
OwnableUpgradeable, UUPSUpgradeable


## State Variables
### lightClient

```solidity
IBridgeLightClient public lightClient;
```


### tokenAddresses

```solidity
address[] public tokenAddresses;
```


### connectors

```solidity
mapping(address => IBridgeConnector) public connectors;
```


### localAddress

```solidity
mapping(address => address) public localAddress;
```


### finalizedEpoch

```solidity
uint256 public finalizedEpoch;
```


### appliedEpoch

```solidity
uint256 public appliedEpoch;
```


### finalizationInterval

```solidity
uint256 public finalizationInterval;
```


### lastFinalizedBlock

```solidity
uint256 public lastFinalizedBlock;
```


### bridgeRoot

```solidity
bytes32 public bridgeRoot;
```


### __gap
gap for upgrade safety <- can be used to add new storage variables(using up to 49  32 byte slots) in new versions of this contract
If used, decrease the number of slots in the next contract that inherits this one(ex. uint256[48] __gap;)


```solidity
uint256[49] __gap;
```


## Functions
### __BridgeBase_init


```solidity
function __BridgeBase_init(IBridgeLightClient light_client, uint256 _finalizationInterval) internal onlyInitializing;
```

### __BridgeBase_init_unchained


```solidity
function __BridgeBase_init_unchained(IBridgeLightClient light_client, uint256 _finalizationInterval)
    internal
    onlyInitializing;
```

### _authorizeUpgrade


```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyOwner;
```

### setFinalizationInterval

Only the owner can call this function.

*Sets the finalization interval.*


```solidity
function setFinalizationInterval(uint256 _finalizationInterval) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_finalizationInterval`|`uint256`|The finalization interval to be set.|


### registeredTokens


```solidity
function registeredTokens() public view returns (address[] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address[]`|An array of addresses of the registered tokens.|


### getBridgeRoot


```solidity
function getBridgeRoot() public view returns (bytes32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|The bridge root as a bytes32 value.|


### registerContract

*Registers a contract with the EthBridge by providing a connector contract.*


```solidity
function registerContract(IBridgeConnector connector) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`connector`|`IBridgeConnector`|The address of the connector contract.|


### applyState

*Applies the given state with proof to the contracts.*


```solidity
function applyState(SharedStructs.StateWithProof calldata state_with_proof) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`state_with_proof`|`SharedStructs.StateWithProof`|The state with proof to be applied.|


### shouldFinalizeEpoch


```solidity
function shouldFinalizeEpoch() public view returns (bool);
```

### finalizeEpoch

*Finalizes the current epoch.*


```solidity
function finalizeEpoch() public;
```

### getStateWithProof


```solidity
function getStateWithProof() public view returns (SharedStructs.StateWithProof memory ret);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`ret`|`SharedStructs.StateWithProof`|finalized states with proof for all tokens|


## Events
### StateApplied
Events


```solidity
event StateApplied(bytes indexed state, address indexed receiver, address indexed connector, uint256 refund);
```

### Finalized

```solidity
event Finalized(uint256 indexed epoch, bytes32 bridgeRoot);
```

### ConnectorRegistered

```solidity
event ConnectorRegistered(address indexed connector);
```

