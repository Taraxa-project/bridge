# TestERC20
[Git Source](https://github.com-VargaElod23/Taraxa-project/bridge/blob/996f61a29d91a8326c805bfdad924088129ae1a7/src/lib/TestERC20.sol)

**Inherits:**
ERC20Upgradeable, OwnableUpgradeable, [IERC20MintableBurnable](/src/connectors/IERC20MintableBurnable.sol/interface.IERC20MintableBurnable.md), UUPSUpgradeable


## Functions
### constructor


```solidity
constructor();
```

### initialize


```solidity
function initialize(string memory name, string memory symbol) public initializer;
```

### _authorizeUpgrade


```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyOwner;
```

### mintTo

*Mints a specified amount of tokens and assigns them to the specified account.*


```solidity
function mintTo(address receiver, uint256 amount) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address to which the tokens will be minted.|
|`amount`|`uint256`|The amount of tokens to be minted.|


### burnFrom

*Destroys a `value` amount of tokens from `account`, deducting from
the caller's allowance.
See [ERC20-_burn](/lib/beacon-light-client/lib/forge-std/src/mocks/MockERC20.sol/contract.MockERC20.md#_burn) and {ERC20-allowance}.
Requirements:
- the caller must have allowance for ``accounts``'s tokens of at least
`value`.*


```solidity
function burnFrom(address account, uint256 value) public virtual;
```

