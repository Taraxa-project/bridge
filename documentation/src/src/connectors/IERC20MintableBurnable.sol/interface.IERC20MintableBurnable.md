# IERC20MintableBurnable
[Git Source](https://github.com/Taraxa-project/bridge/blob/e4d318b451d9170f9f2dde80fe4263043786ba03/src/connectors/IERC20MintableBurnable.sol)

**Inherits:**
IERC20


## Functions
### mintTo

*Mints a specified amount of tokens and assigns them to the specified account.*


```solidity
function mintTo(address receiver, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address to which the tokens will be minted.|
|`amount`|`uint256`|The amount of tokens to be minted.|


### burnFrom

*Destroys a `value` amount of tokens from `account`, deducting from
the caller's allowance.
See [ERC20-_burn](/lib/beacon-light-client/lib/create3-deploy/lib/solmate/src/tokens/ERC1155.sol/abstract.ERC1155.md#_burn) and {ERC20-allowance}.
Requirements:
- the caller must have allowance for ``accounts``'s tokens of at least
`value`.*


```solidity
function burnFrom(address account, uint256 value) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address from which the tokens will be burnt.|
|`value`|`uint256`|The amount of tokens to burn.|


