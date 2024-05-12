# BridgeConnectorBase
[Git Source](https://github.com-VargaElod23/Taraxa-project/bridge/blob/996f61a29d91a8326c805bfdad924088129ae1a7/src/connectors/BridgeConnectorBase.sol)

**Inherits:**
[IBridgeConnector](/src/connectors/IBridgeConnector.sol/interface.IBridgeConnector.md), OwnableUpgradeable, UUPSUpgradeable


## State Variables
### feeToClaim

```solidity
mapping(address => uint256) public feeToClaim;
```


### __gap
gap for upgrade safety <- can be used to add new storage variables(using up to 49  32 byte slots) in new versions of this contract
If used, decrease the number of slots in the next contract that inherits this one(ex. uint256[48] __gap;)


```solidity
uint256[49] __gap;
```


## Functions
### receive


```solidity
receive() external payable;
```

### __BridgeConnectorBase_init


```solidity
function __BridgeConnectorBase_init(address bridge) public onlyInitializing;
```

### __BridgeConnectorBase_init_unchained


```solidity
function __BridgeConnectorBase_init_unchained(address bridge) internal onlyInitializing;
```

### _authorizeUpgrade


```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyOwner;
```

### refund

*Refunds the specified amount to the given receiver.*


```solidity
function refund(address payable receiver, uint256 amount) public override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address payable`|The address of the receiver.|
|`amount`|`uint256`|The amount to be refunded.|


### applyState


```solidity
function applyState(bytes calldata) internal virtual returns (address[] memory);
```

### applyStateWithRefund

*Applies the given state with a refund to the specified receiver.*


```solidity
function applyStateWithRefund(bytes calldata _state, address payable refund_receiver, uint256 common_part)
    public
    override
    onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_state`|`bytes`|The state to apply.|
|`refund_receiver`|`address payable`|The address of the refund_receiver.|
|`common_part`|`uint256`|The common part of the refund.|


## Events
### Funded
Events


```solidity
event Funded(address indexed sender, address indexed connectorBase, uint256 amount);
```

### Refunded

```solidity
event Refunded(address indexed receiver, uint256 amount);
```

### StateApplied

```solidity
event StateApplied(bytes indexed state, address indexed receiver, uint256 amount);
```

