# ERC20LockingConnector
[Git Source](https://github.com/Taraxa-project/bridge/blob/e4d318b451d9170f9f2dde80fe4263043786ba03/src/connectors/ERC20LockingConnector.sol)

**Inherits:**
[TokenConnectorBase](/src/connectors/TokenConnectorBase.sol/abstract.TokenConnectorBase.md)


## Functions
### initialize


```solidity
function initialize(address bridge, IERC20 tokenAddress, address token_on_other_network) public payable initializer;
```

### applyState

*Applies the given state to the token contract by transfers.*


```solidity
function applyState(bytes calldata _state) internal override returns (address[] memory accounts);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_state`|`bytes`|The state to be applied.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`accounts`|`address[]`|Affected accounts that we should split fee between|


### lock

The amount of tokens to burn must be approved by the sender

*Locks the specified amount of tokens to transfer them to the other network.*


```solidity
function lock(uint256 value) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`value`|`uint256`|The amount of tokens to lock.|


### claim

The caller must send enough Ether to cover the fees.

*Allows the caller to claim tokens*


```solidity
function claim() public payable override;
```

## Events
### Locked
Events


```solidity
event Locked(address indexed account, uint256 value);
```

