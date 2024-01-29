// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library SharedStructs {
    struct StateWithAddress {
        address contractAddress;
        bytes state;
    }

    struct ContractStateHash {
        address contractAddress;
        bytes32 stateHash;
    }

    struct BridgeState {
        uint256 epoch;
        StateWithAddress[] states;
    }

    struct StateWithProof {
        BridgeState state;
        ContractStateHash[] state_hashes;
    }
}
