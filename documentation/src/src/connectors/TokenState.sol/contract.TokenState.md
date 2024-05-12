# TokenState
[Git Source](https://github.com-VargaElod23/Taraxa-project/bridge/blob/996f61a29d91a8326c805bfdad924088129ae1a7/src/connectors/TokenState.sol)

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
event TransferAdded(address indexed account, address indexed tokenState, uint256 indexed amount);
```

### Initialized

```solidity
event Initialized(uint256 indexed epoch);
```

