# TokenConnectorBase
[Git Source](https://github.com-VargaElod23/Taraxa-project/bridge/blob/996f61a29d91a8326c805bfdad924088129ae1a7/src/connectors/TokenConnectorBase.sol)

**Inherits:**
[BridgeConnectorBase](/src/connectors/BridgeConnectorBase.sol/abstract.BridgeConnectorBase.md)


## State Variables
### token

```solidity
address public token;
```


### otherNetworkAddress

```solidity
address public otherNetworkAddress;
```


### state

```solidity
TokenState public state;
```


### finalizedState

```solidity
TokenState public finalizedState;
```


### toClaim

```solidity
mapping(address => uint256) public toClaim;
```


## Functions
### TokenConnectorBase_init


```solidity
function TokenConnectorBase_init(address bridge, address _token, address token_on_other_network)
    public
    onlyInitializing;
```

### __TokenConnectorBase_init


```solidity
function __TokenConnectorBase_init(address bridge, address _token, address token_on_other_network)
    internal
    onlyInitializing;
```

### epoch


```solidity
function epoch() public view returns (uint256);
```

### deserializeTransfers


```solidity
function deserializeTransfers(bytes memory data) internal pure returns (Transfer[] memory);
```

### finalizedSerializedTransfers


```solidity
function finalizedSerializedTransfers() internal view returns (bytes memory);
```

### isStateEmpty


```solidity
function isStateEmpty() external view override returns (bool);
```

### finalize


```solidity
function finalize(uint256 epoch_to_finalize) public override onlyOwner returns (bytes32);
```

### getFinalizedState

*Retrieves the finalized state of the bridgeable contract.*


```solidity
function getFinalizedState() public view override returns (bytes memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|A bytes serialized finalized state|


### getContractAddress

*Returns the address of the underlying contract in this network*


```solidity
function getContractAddress() public view returns (address);
```

### getBridgedContractAddress

*Returns the address of the bridged contract in the other network*


```solidity
function getBridgedContractAddress() external view returns (address);
```

### claim

*Allows the caller to claim tokens by sending Ether to this function to cover fees.
This function is virtual and must be implemented by derived contracts.*


```solidity
function claim() public payable virtual;
```

## Events
### Finalized
Events


```solidity
event Finalized(uint256 indexed epoch);
```

### Initialized

```solidity
event Initialized(address indexed token, address indexed otherNetworkAddress, address indexed tokenState);
```

### StateApplied

```solidity
event StateApplied(bytes state);
```

### ClaimAccrued

```solidity
event ClaimAccrued(address indexed account, uint256 value);
```

### Claimed

```solidity
event Claimed(address indexed account, uint256 value);
```

