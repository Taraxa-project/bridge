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

    struct FinalizedBlock {
        bytes32 blockHash;
        FinalizationData block;
        uint256 finalizedAt;
    }

    struct Vote {
        uint256 period;
        bytes32 blockHash;
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
    PillarBlock.FinalizedBlock public finalized;
    mapping(address => uint256) public validatorVoteCounts;
    uint256 public totalWeight;
    uint256 public threshold;
    uint256 public pillarBlockInterval;

    constructor(PillarBlock.WithChanges memory _genesisBlock, uint256 _threshold, uint256 _pillarBlockInterval) {
        finalized = PillarBlock.FinalizedBlock(PillarBlock.getHash(_genesisBlock), _genesisBlock.block, block.number);
        processValidatorChanges(_genesisBlock.validatorChanges);
        threshold = _threshold;
        pillarBlockInterval = _pillarBlockInterval;
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
     * @param blocks list of PillarBlockWithChanges.
     * @param lastBlockSigs An array of Signature structs representing the signatures of the last block.
     */
    function finalizeBlocks(PillarBlock.WithChanges[] memory blocks, CompactSignature[] memory lastBlockSigs) public {
        for (uint256 i = 0; i < blocks.length; i++) {
            bytes32 pbh = PillarBlock.getHash(blocks[i]);
            require(blocks[i].block.prevHash == finalized.blockHash, "block.prevHash != finalized.blockHash");
            require(
                blocks[i].block.period == finalized.block.period + pillarBlockInterval,
                "Finalized block should have number pillarBlockInterval greater than latest"
            );
            // this should be processed before the signatures verification to have a proper weights
            processValidatorChanges(blocks[i].validatorChanges);
            // verify signatures only for the last block
            if (i == (blocks.length - 1)) {
                uint256 weight =
                    getSignaturesWeight(PillarBlock.getVoteHash(blocks[i].block.period, pbh), lastBlockSigs);
                require(weight >= threshold, "Signatures weight is less than threshold");
            }
            finalized = PillarBlock.FinalizedBlock(pbh, blocks[i].block, block.number);
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
}
