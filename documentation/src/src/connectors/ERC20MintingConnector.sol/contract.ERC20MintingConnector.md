# ERC20MintingConnector
[Git Source](https://github.com-VargaElod23/Taraxa-project/bridge/blob/996f61a29d91a8326c805bfdad924088129ae1a7/src/connectors/ERC20MintingConnector.sol)

**Inherits:**
[TokenConnectorBase](/src/connectors/TokenConnectorBase.sol/abstract.TokenConnectorBase.md)


## Functions
### initialize


```solidity
function initialize(address bridge, IERC20MintableBurnable tokenAddress, address token_on_other_network)
    public
    initializer;
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


### burn

The amount of tokens to burn must be approved by the sender

*Burns a specified amount of tokens to transfer them to the other network.*


```solidity
function burn(uint256 amount) public payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens to burn.|


### claim

The caller must send enough Ether to cover the fees.

*Allows the caller to claim tokens*


```solidity
function claim() public payable override;
```

## Events
### Burned
Events


```solidity
event Burned(address indexed account, uint256 value);
```

