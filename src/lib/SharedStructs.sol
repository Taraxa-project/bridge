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

    function getBridgeRoot(
        uint256 epoch,
        ContractStateHash[] memory state_hashes
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(epoch, state_hashes));
    }
}
