// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../lib/Maths.sol";
import "../lib/ILightClient.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

struct CompactSignature {
    bytes32 r;
    bytes32 vs;
}

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
        bytes32 bridgeRoot;
        bytes32 prevHash;
    }

    struct WithChanges {
        FinalizationData block;
        VoteCountChange[] validatorChanges;
    }

    struct PendingBlock {
        bytes32 blockHash;
        WithChanges blockWithChanges;
        bool finalized;
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

contract TaraClient is IBridgeLightClient {
    PillarBlock.PendingBlock public pending;

    PillarBlock.FinalizedBlock public finalized;
    mapping(address => uint256) public validatorVoteCounts;
    uint256 public totalWeight;
    uint256 public threshold;
    uint256 public delay;
    uint256 public pillarBlockInterval;

    constructor(PillarBlock.WithChanges memory genesis_block, uint256 _threshold, uint256 _pillarBlockInterval) {
        finalized = PillarBlock.FinalizedBlock(PillarBlock.getHash(genesis_block), genesis_block.block, block.number);
        processValidatorChanges(genesis_block.validatorChanges);
        threshold = _threshold;
        pillarBlockInterval = _pillarBlockInterval;
        pending = PillarBlock.PendingBlock(PillarBlock.getHash(genesis_block), genesis_block, true);
    }

    function getPending() public view returns (PillarBlock.PendingBlock memory) {
        return pending;
    }

    function getPendingPillarBlock() public view returns (PillarBlock.WithChanges memory) {
        return pending.blockWithChanges;
    }

    function getFinalized() public view returns (PillarBlock.FinalizedBlock memory) {
        return finalized;
    }

    /**
     * @dev Returns the finalized bridge root.
     * @return The finalized bridge root as a bytes32 value.
     */
    function getFinalizedBridgeRoot() external view returns (bytes32) {
        return finalized.block.bridgeRoot;
    }

    /**
     * @dev Sets the vote weight threshold value.
     * @param _threshold The new threshold value to be set.
     */
    // TODO: do we need this to be called by some "owner"?
    function setThreshold(uint256 _threshold) public {
        threshold = _threshold;
    }

    /**
     * @dev Processes the changes in validator weights.
     * @param validatorChanges An array of VoteCountChange structs representing the changes in validator vote counts.
     *  optimize for gas cost!!
     */
    function processValidatorChanges(PillarBlock.VoteCountChange[] memory validatorChanges) public {
        for (uint256 i = 0; i < validatorChanges.length; i++) {
            validatorVoteCounts[validatorChanges[i].validator] =
                Maths.add(validatorVoteCounts[validatorChanges[i].validator], validatorChanges[i].change);
            totalWeight = Maths.add(totalWeight, validatorChanges[i].change);
        }
    }

    /**
     * @dev Finalizes blocks by verifying the signatures for the last blocks
     * @param encoded_blocks list if PillarBlockWithChanges.
     * @param last_block_sigs An array of Signature structs representing the signatures of the last block.
     */
    function finalizeBlocks(bytes[] memory encoded_blocks, CompactSignature[] memory last_block_sigs) public {
        for (uint256 i = 0; i < encoded_blocks.length; i++) {
            PillarBlock.WithChanges memory b = PillarBlock.fromBytes(encoded_blocks[i]);
            bytes32 pbh = PillarBlock.getHash(encoded_blocks[i]);
            require(b.block.prevHash == finalized.blockHash, "block.prevHash != finalized.hash");
            // this should be processed before the signatures verification to have a proper weights
            processValidatorChanges(b.validatorChanges);
            // verify signatures only for the last block
            if (i == (encoded_blocks.length - 1)) {
                uint256 weight = getSignaturesWeight(PillarBlock.getVoteHash(b.block.period, pbh), last_block_sigs);
                require(weight >= threshold, "Signatures weight is less than threshold");
            }
            _finalizeBlock(b, pbh);
        }
    }

    /**
     * @dev Calculates the total weight of the signatures
     * @param h The hash for verification.
     * @param signatures An array of signatures.
     * @return weight The total weight of the signatures.
     */
    function getSignaturesWeight(bytes32 h, CompactSignature[] memory signatures)
        public
        view
        returns (uint256 weight)
    {
        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = ECDSA.recover(h, signatures[i].r, signatures[i].vs);
            weight += validatorVoteCounts[signer];
        }
    }

    /**
     * @dev Finalizes
     * @param b The PillarBlockWithChanges struct containing the block data and validators changes.
     * @param h Pillar block hash
     */
    function _finalizeBlock(PillarBlock.WithChanges memory b, bytes32 h) internal {
        require(b.block.prevHash == finalized.blockHash, "block.prevHash != finalized.blockHash");
        require(
            b.block.period == finalized.block.period + pillarBlockInterval,
            "Pending block should have number pillarBlockInterval greater than latest"
        );
        finalized = PillarBlock.FinalizedBlock(h, b.block, block.number);
    }
}
