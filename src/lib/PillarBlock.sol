// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {CompactSignature} from "./CompactSignature.sol";

library PillarBlock {
    /**
     * Vote count change coming from a validator
     * Encapsulates the address of the validator
     * and the vote count of the validator vote(signature)
     */
    struct VoteCountChange {
        address validator;
        int32 change;
    }

    struct FinalizationData {
        uint256 period;
        bytes32 stateRoot;
        bytes32 prevHash;
        bytes32 bridgeRoot;
        uint256 epoch;
    }

    struct WithChanges {
        FinalizationData block;
        VoteCountChange[] validatorChanges;
    }

    struct FinalizedBlock {
        bytes32 blockHash;
        FinalizationData block;
        uint256 finalizedAt;
    }

    struct Vote {
        uint256 period;
        bytes32 block_hash;
    }

    struct SignedVote {
        Vote vote;
        CompactSignature signature;
    }

    function fromBytes(bytes memory b) internal pure returns (WithChanges memory) {
        return abi.decode(b, (WithChanges));
    }

    function getHash(bytes memory b) internal pure returns (bytes32) {
        return keccak256(b);
    }

    function getHash(WithChanges memory b) internal pure returns (bytes32) {
        return keccak256(abi.encode(b));
    }

    function getHash(Vote memory b) internal pure returns (bytes32) {
        return keccak256(abi.encode(b));
    }

    function getHash(SignedVote memory b) internal pure returns (bytes32) {
        return keccak256(abi.encode(b));
    }

    function getVoteHash(WithChanges memory b) internal pure returns (bytes32) {
        return keccak256(abi.encode(b.block.period, getHash(b)));
    }

    function getVoteHash(uint256 period, bytes32 bh) internal pure returns (bytes32) {
        return keccak256(abi.encode(period, bh));
    }
}
