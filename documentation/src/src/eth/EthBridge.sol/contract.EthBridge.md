# EthBridge
[Git Source](https://github.com-VargaElod23/Taraxa-project/bridge/blob/996f61a29d91a8326c805bfdad924088129ae1a7/src/eth/EthBridge.sol)

**Inherits:**
[BridgeBase](/src/lib/BridgeBase.sol/abstract.BridgeBase.md)


## Functions
### initialize


```solidity
function initialize(IERC20MintableBurnable tara, IBridgeLightClient light_client, uint256 finalizationInterval)
    public
    initializer;
```

### __initialize_EthBridge_unchained


```solidity
function __initialize_EthBridge_unchained(
    IERC20MintableBurnable tara,
    IBridgeLightClient light_client,
    uint256 finalizationInterval
) internal onlyInitializing;
```

## Events
### Initialized
Events


```solidity
event Initialized(address indexed tara, address indexed light_client, uint256 finalizationInterval);
```

