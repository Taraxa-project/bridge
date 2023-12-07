// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library SharedStructs {
    struct TokenEpochState {
        uint256 epoch;
        Transfer[] transfers;
    }

    struct Transfer {
        address account;
        uint256 amount;
    }

    struct BridgeState {
        uint256 epoch;
        bytes32[] hashes;
    }

    struct Proof {
        bytes32 root_hash;
        bytes32[] token_names;
        BridgeState state;
    }

    struct StateWithProof {
        TokenEpochState[] state;
        Proof proof;
    }
}
