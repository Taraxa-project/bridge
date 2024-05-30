# TokenConnectorBase
[Git Source](https://github.com/Taraxa-project/bridge/blob/e4d318b451d9170f9f2dde80fe4263043786ba03/src/connectors/TokenConnectorBase.sol)

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


### getContractSource

*Returns the address of the underlying contract in this network*


```solidity
function getContractSource() public view returns (address);
```

### getContractDestination

*Returns the address of the bridged contract on the other network*


```solidity
function getContractDestination() external view returns (address);
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

### ClaimAccrued

```solidity
event ClaimAccrued(address indexed account, uint256 value);
```

### Claimed

```solidity
event Claimed(address indexed account, uint256 value);
```

