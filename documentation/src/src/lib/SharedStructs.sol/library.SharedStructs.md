# SharedStructs
[Git Source](https://github.com/Taraxa-project/bridge/blob/e4d318b451d9170f9f2dde80fe4263043786ba03/src/lib/SharedStructs.sol)


## Functions
### getBridgeRoot


```solidity
function getBridgeRoot(uint256 epoch, ContractStateHash[] memory state_hashes) internal pure returns (bytes32);
```

## Structs
### StateWithAddress

```solidity
struct StateWithAddress {
    address contractAddress;
    bytes state;
}
```

### ContractStateHash

```solidity
struct ContractStateHash {
    address contractAddress;
    bytes32 stateHash;
}
```

### BridgeState

```solidity
struct BridgeState {
    uint256 epoch;
    StateWithAddress[] states;
}
```

### StateWithProof

```solidity
struct StateWithProof {
    BridgeState state;
    ContractStateHash[] state_hashes;
}
```

