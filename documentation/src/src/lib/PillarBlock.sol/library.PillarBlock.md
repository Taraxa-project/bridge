# PillarBlock
[Git Source](https://github.com/Taraxa-project/bridge/blob/e4d318b451d9170f9f2dde80fe4263043786ba03/src/lib/PillarBlock.sol)


## Functions
### fromBytes


```solidity
function fromBytes(bytes memory b) internal pure returns (WithChanges memory);
```

### getHash


```solidity
function getHash(bytes memory b) internal pure returns (bytes32);
```

### getHash


```solidity
function getHash(WithChanges memory b) internal pure returns (bytes32);
```

### getHash


```solidity
function getHash(Vote memory b) internal pure returns (bytes32);
```

### getHash


```solidity
function getHash(SignedVote memory b) internal pure returns (bytes32);
```

### getVoteHash


```solidity
function getVoteHash(WithChanges memory b) internal pure returns (bytes32);
```

### getVoteHash


```solidity
function getVoteHash(uint256 period, bytes32 bh) internal pure returns (bytes32);
```

## Structs
### VoteCountChange
Vote count change coming from a validator
Encapsulates the address of the validator
and the vote count of the validator vote(signature)


```solidity
struct VoteCountChange {
    address validator;
    int32 change;
}
```

### FinalizationData

```solidity
struct FinalizationData {
    uint256 period;
    bytes32 stateRoot;
    bytes32 bridgeRoot;
    bytes32 prevHash;
}
```

### WithChanges

```solidity
struct WithChanges {
    FinalizationData block;
    VoteCountChange[] validatorChanges;
}
```

### FinalizedBlock

```solidity
struct FinalizedBlock {
    bytes32 blockHash;
    FinalizationData block;
    uint256 finalizedAt;
}
```

### Vote

```solidity
struct Vote {
    uint256 period;
    bytes32 block_hash;
}
```

### SignedVote

```solidity
struct SignedVote {
    Vote vote;
    CompactSignature signature;
}
```

