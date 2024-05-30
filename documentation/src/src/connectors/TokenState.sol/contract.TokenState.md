# TokenState
[Git Source](https://github.com/Taraxa-project/bridge/blob/e4d318b451d9170f9f2dde80fe4263043786ba03/src/connectors/TokenState.sol)

**Inherits:**
Ownable


## State Variables
### epoch

```solidity
uint256 public epoch;
```


### accounts

```solidity
address[] accounts;
```


### balances

```solidity
mapping(address => uint256) balances;
```


## Functions
### constructor


```solidity
constructor(uint256 _epoch) Ownable(msg.sender);
```

### empty


```solidity
function empty() public view returns (bool);
```

### increaseEpoch


```solidity
function increaseEpoch() public onlyOwner;
```

### addAmount


```solidity
function addAmount(address account, uint256 amount) public onlyOwner;
```

### getTransfers


```solidity
function getTransfers() public view returns (Transfer[] memory);
```

## Events
### TransferAdded
Events


```solidity
event TransferAdded(address indexed account, uint256 amount);
```

