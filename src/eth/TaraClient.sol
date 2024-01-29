// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../lib/ILightClient.sol";

struct WeightChange {
    address validator;
    int96 change;
}

struct PillarBlock {
    uint256 number;
    bytes32 prevHash;
    bytes32 stateRoot;
    bytes32 bridgeRoot;
}

struct PillarBlockWithChanges {
    PillarBlock block;
    WeightChange[] validatorChanges;
}

struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

struct FinalizedBlock {
    bytes32 blockHash;
    uint256 finalizedAt;
    PillarBlock block;
}

contract TaraClient is IBridgeLightClient {
    PillarBlockWithChanges pending;
    bool pendingFinalized;

    FinalizedBlock public finalized;
    mapping(address => int96) public validators;
    int256 totalWeight;
    int256 threshold;
    uint256 delay;

    constructor(WeightChange[] memory _validatorChanges, int256 _threshold, uint256 _delay, bytes32 _initialHash) {
        processValidatorChanges(_validatorChanges);
        threshold = _threshold;
        delay = _delay;
        finalized = FinalizedBlock(_initialHash, 0, PillarBlock(0, 0, 0, 0));
    }

    function getPending() public view returns (PillarBlockWithChanges memory) {
        return pending;
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
    function setThreshold(int256 _threshold) public {
        threshold = _threshold;
    }

    // function recover(bytes32 hash, Signature memory sig) public pure returns (address) {
    //     return ecrecover(hash, sig.v, sig.r, sig.s);
    // }

    /**
     * @dev Processes the changes in validator weights.
     * @param validatorChanges An array of WeightChange structs representing the changes in validator weights.
     */
    function processValidatorChanges(WeightChange[] memory validatorChanges) public {
        for (uint256 i = 0; i < validatorChanges.length; i++) {
            validators[validatorChanges[i].validator] += validatorChanges[i].change;
            totalWeight += validatorChanges[i].change;
        }
    }

    /**
     * @dev Returns the hash of a PillarBlockWithChanges struct.
     * @param b The PillarBlockWithChanges struct.
     * @return The hash of the PillarBlockWithChanges struct.
     */
    function getBlockHash(PillarBlockWithChanges memory b) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                b.block.number, b.block.prevHash, b.block.stateRoot, b.block.bridgeRoot, abi.encode(b.validatorChanges)
            )
        );
    }

    /**
     * @dev Finalizes a block by verifying the signatures and processing the changes.
     * @param b PillarBlockWithChanges.
     * @param signatures An array of Signature structs representing the signatures of the block.
     */
    function finalizeBlock(PillarBlockWithChanges memory b, Signature[] memory signatures) public {
        _finalizeBlock(b, signatures);
    }

    /**
     * @dev Calculates the total weight of the signatures
     * @param h The hash for verification.
     * @param signatures An array of signatures.
     * @return weight The total weight of the signatures.
     */
    function getSignaturesWeight(bytes32 h, Signature[] memory signatures) public view returns (int256 weight) {
        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = ecrecover(h, signatures[i].v, signatures[i].r, signatures[i].s);
            weight += validators[signer];
        }
    }

    function setPending(PillarBlockWithChanges memory b) internal {
        pending = b;
        pendingFinalized = false;
    }

    /**
     * @dev Adds a pending block
     * @param b The PillarBlockWithChanges struct representing the pending block.
     */
    function addPendingBlock(PillarBlockWithChanges memory b) public {
        require(block.number >= finalized.finalizedAt + delay, "The delay isn't passed yet");

        if (pendingFinalized) {
            require(finalized.block.number + 1 == b.block.number, "Block number + 1 != finalized block number");
            require(b.block.prevHash == finalized.blockHash, "Block prevHash != finalized block hash");
            setPending(b);
            return;
        }

        require(pending.block.number + 1 == b.block.number, "Block number + 1 != pending block number");
        bytes32 pending_hash = getBlockHash(pending);
        require(b.block.prevHash == pending_hash, "Block prevHash != pending block hash");
        finalized = FinalizedBlock(pending_hash, block.number, pending.block);
        processValidatorChanges(pending.validatorChanges);
        setPending(b);
    }

    /**
     * @dev Finalizes a pending block by providing the required signatures.
     * @param signatures The array of signatures required to finalize the block.
     */
    function finalizePendingBlock(Signature[] memory signatures) public {
        _finalizeBlock(pending, signatures);
        pendingFinalized = true;
    }

    /**
     * @dev Finalizes
     * @param b The PillarBlockWithChanges struct containing the block data and validators changes.
     * @param signatures An array of signatures.
     */
    function _finalizeBlock(PillarBlockWithChanges memory b, Signature[] memory signatures) internal {
        require(finalized.block.number + 1 == b.block.number, "Pending block should have number 1 greater than latest");
        require(b.block.prevHash == finalized.blockHash, "Pending block must be child of latest");
        bytes32 h = getBlockHash(b);
        int256 weight = getSignaturesWeight(h, signatures);
        require(weight >= threshold, "Not enough weight");
        processValidatorChanges(b.validatorChanges);
        finalized = FinalizedBlock(h, block.number, b.block);
    }
}
