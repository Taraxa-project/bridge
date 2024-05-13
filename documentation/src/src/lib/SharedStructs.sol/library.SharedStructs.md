# SharedStructs
[Git Source](https://github.com-VargaElod23/Taraxa-project/bridge/blob/996f61a29d91a8326c805bfdad924088129ae1a7/src/lib/SharedStructs.sol)


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

