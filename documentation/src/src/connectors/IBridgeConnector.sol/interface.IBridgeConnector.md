# IBridgeConnector
[Git Source](https://github.com-VargaElod23/Taraxa-project/bridge/blob/996f61a29d91a8326c805bfdad924088129ae1a7/src/connectors/IBridgeConnector.sol)

*Interface for bridgeable contracts.*


## Functions
### finalize

*Finalizes the bridge operation and returns a bytes32 value hash.*


```solidity
function finalize(uint256 epoch) external returns (bytes32 finalizedHash);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`epoch`|`uint256`|The epoch to be finalized|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`finalizedHash`|`bytes32`|of the finalized state|


### isStateEmpty

*Checks if the state is empty.*


```solidity
function isStateEmpty() external view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if the state is empty, false otherwise|


### getFinalizedState

*Retrieves the finalized state of the bridgeable contract.*


```solidity
function getFinalizedState() external view returns (bytes memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|A bytes serialized finalized state|


### getContractAddress

*Returns the address of the underlying contract in this network*


```solidity
function getContractAddress() external view returns (address);
```

### getBridgedContractAddress

*Returns the address of the bridged contract in the other network*


```solidity
function getBridgedContractAddress() external view returns (address);
```

### applyStateWithRefund

*Applies the given state with a refund to the specified receiver.*


```solidity
function applyStateWithRefund(bytes calldata _state, address payable receiver, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_state`|`bytes`|The state to apply.|
|`receiver`|`address payable`|The address of the receiver.|
|`amount`|`uint256`|The amount of refund to send.|


### refund

*Refunds the given amount to the receiver*


```solidity
function refund(address payable receiver, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address payable`|The receiver of the refund|
|`amount`|`uint256`|The amount to be refunded|


