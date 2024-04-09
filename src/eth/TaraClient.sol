// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../lib/ILightClient.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

struct CompactSignature {
    bytes32 r;
    bytes32 vs;
}

library PillarBlock {
    /**
     * Weight change coming from a validator
     * Encapsulates the address of the validator
     * and the weight of the validator vote(signature)
     */
    struct WeightChange {
        address validator;
        int96 change;
    }

    struct FinalizationData {
        uint256 period;
        bytes32 stateRoot;
        bytes32 bridgeRoot;
        bytes32 prevHash;
    }

    struct WithChanges {
        FinalizationData block;
        WeightChange[] validatorChanges;
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

    function fromBytes(
        bytes memory b
    ) internal pure returns (WithChanges memory) {
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

    function getVoteHash(
        uint256 period,
        bytes32 bh
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(period, bh));
    }
}

contract TaraClient is IBridgeLightClient {
    PillarBlock.WithChanges pending;
    bytes32 public pendingHash;
    bool public pendingFinalized;

    PillarBlock.FinalizedBlock public finalized;
    mapping(address => int96) public validators;
    int256 public totalWeight;
    int256 public threshold;
    uint256 public delay;

    uint256 refund;

    constructor(
        PillarBlock.WeightChange[] memory _validatorChanges,
        int256 _threshold,
        uint256 _delay
    ) {
        processValidatorChanges(_validatorChanges);
        threshold = _threshold;
        delay = _delay;

        pendingHash = PillarBlock.getHash(pending);
    }

    function getPending() public view returns (PillarBlock.WithChanges memory) {
        return pending;
    }

    /**
     * @dev Returns the finalized bridge root.
     * @return The finalized bridge root as a bytes32 value.
     */
    function getFinalizedBridgeRoot() external view returns (bytes32) {
        return finalized.block.bridgeRoot;
    }

    function refundAmount() external view returns (uint256) {
        return refund;
    }

    /**
     * @dev Sets the vote weight threshold value.
     * @param _threshold The new threshold value to be set.
     */
    // TODO: do we need this to be called by some "owner"?
    function setThreshold(int256 _threshold) public {
        threshold = _threshold;
    }

    /**
     * @dev Processes the changes in validator weights.
     * @param validatorChanges An array of WeightChange structs representing the changes in validator weights.
     *  optimize for gas cost!!
     */
    function processValidatorChanges(
        PillarBlock.WeightChange[] memory validatorChanges
    ) public {
        for (uint256 i = 0; i < validatorChanges.length; i++) {
            validators[validatorChanges[i].validator] += validatorChanges[i]
                .change;
            totalWeight += validatorChanges[i].change;
        }
    }

    /**
     * @dev Finalizes a block by verifying the signatures and processing the changes.
     * @param b PillarBlockWithChanges.
     * @param signatures An array of Signature structs representing the signatures of the block.
     */

    function finalizeBlock(
        bytes memory b,
        CompactSignature[] memory signatures
    ) public {
        _finalizeBlock(
            PillarBlock.fromBytes(b),
            PillarBlock.getHash(b),
            signatures
        );
    }

    /**
     * @dev Calculates the total weight of the signatures
     * @param h The hash for verification.
     * @param signatures An array of signatures.
     * @return weight The total weight of the signatures.
     */
    function getSignaturesWeight(
        bytes32 h,
        CompactSignature[] memory signatures
    ) public view returns (int256 weight) {
        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = ECDSA.recover(
                h,
                signatures[i].r,
                signatures[i].vs
            );
            weight += validators[signer];
        }
    }

    function setPending(PillarBlock.WithChanges memory b, bytes32 ph) internal {
        pendingHash = ph;
        pending = b;
        pendingFinalized = false;
    }

    /**
     * @dev Adds a pending block
     * @param b RLP encoded PillarBlockWithChanges struct representing the pending block.
     */
    function addPendingBlock(bytes memory b) public {
        PillarBlock.WithChanges memory pb = PillarBlock.fromBytes(b);
        bytes32 ph = PillarBlock.getHash(b);

        require(
            block.number >= finalized.finalizedAt + delay,
            "The delay isn't passed yet"
        );

        if (pendingFinalized) {
            require(
                finalized.block.period + 1 == pb.block.period,
                "Block number + 1 != finalized block number"
            );
            require(
                pb.block.prevHash == finalized.blockHash,
                "Block prevHash != finalized block hash"
            );
            setPending(pb, ph);
            return;
        }

        require(
            pending.block.period + 1 == pb.block.period,
            "Block period + 1 != pending block period"
        );
        require(
            pb.block.prevHash == pendingHash,
            "Block prevHash != pending block hash"
        );
        finalized = PillarBlock.FinalizedBlock(
            pendingHash,
            pending.block,
            block.number
        );
        processValidatorChanges(pending.validatorChanges);
        setPending(pb, ph);
    }

    /**
     * @dev Finalizes a pending block by providing the required signatures.
     * @param signatures The array of signatures required to finalize the block.
     */
    function finalizePendingBlock(CompactSignature[] memory signatures) public {
        _finalizeBlock(pending, pendingHash, signatures);
        pendingFinalized = true;
    }

    /**
     * @dev Finalizes
     * @param b The PillarBlockWithChanges struct containing the block data and validators changes.
     * @param signatures An array of signatures.
     */
    function _finalizeBlock(
        PillarBlock.WithChanges memory b,
        bytes32 h,
        CompactSignature[] memory signatures
    ) internal {
        uint256 gasleftbefore = gasleft();
        require(
            finalized.block.period + 1 == b.block.period,
            "Pending block should have number 1 greater than latest"
        );
        require(
            b.block.prevHash == finalized.blockHash,
            "Pending block must be child of latest"
        );
        int256 weight = getSignaturesWeight(
            PillarBlock.getVoteHash(b.block.period, h),
            signatures
        );
        require(weight >= threshold, "Not enough weight");
        processValidatorChanges(b.validatorChanges);
        finalized = PillarBlock.FinalizedBlock(h, b.block, block.number);
        refund = (gasleftbefore - gasleft()) * tx.gasprice;
    }
}
