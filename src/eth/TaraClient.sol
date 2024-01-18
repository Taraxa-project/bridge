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
    PillarBlockWithChanges public pending;
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

    function getFinalizedBridgeRoot() external view returns (bytes32) {
        return finalized.block.bridgeRoot;
    }

    function setThreshold(int256 _threshold) public {
        threshold = _threshold;
    }

    // function recover(bytes32 hash, Signature memory sig) public pure returns (address) {
    //     return ecrecover(hash, sig.v, sig.r, sig.s);
    // }

    function processValidatorChanges(WeightChange[] memory validatorChanges) public {
        for (uint256 i = 0; i < validatorChanges.length; i++) {
            validators[validatorChanges[i].validator] += validatorChanges[i].change;
            totalWeight += validatorChanges[i].change;
        }
    }

    function getBlockHash(PillarBlockWithChanges memory b) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                b.block.number, b.block.prevHash, b.block.stateRoot, b.block.bridgeRoot, abi.encode(b.validatorChanges)
            )
        );
    }

    function finalizeBlock(PillarBlockWithChanges memory b, Signature[] memory signatures) public {
        _finalizeBlock(b, signatures);
    }

    function checkSignatures(bytes32 h, Signature[] memory signatures) public view returns (int256 weight) {
        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = ecrecover(h, signatures[i].v, signatures[i].r, signatures[i].s);
            weight += validators[signer];
        }
    }

    function addPendingBlock(PillarBlockWithChanges memory b) public {
        require(block.number >= finalized.finalizedAt + delay, "Delay not passed");

        if (finalized.block.number + 1 == b.block.number) {
            require(b.block.prevHash == finalized.blockHash, "Pending block must be child of latest");
            pending = b;
        } else {
            require(
                pending.block.number + 1 == b.block.number, "Pending block should have number 1 greater than latest"
            );
            require(b.block.prevHash == getBlockHash(pending), "Pending block must be child of latest");
            finalized = FinalizedBlock(getBlockHash(pending), block.number, pending.block);
            pending = b;
        }
    }

    function finalizePendingBlock(Signature[] memory signatures) public {
        finalizeBlock(pending, signatures);
    }

    function _finalizeBlock(PillarBlockWithChanges memory b, Signature[] memory signatures) internal {
        require(finalized.block.number + 1 == b.block.number, "Pending block should have number 1 greater than latest");
        require(b.block.prevHash == finalized.blockHash, "Pending block must be child of latest");
        bytes32 h = getBlockHash(b);
        int256 weight = checkSignatures(h, signatures);
        require(weight >= threshold, "Not enough weight");
        processValidatorChanges(b.validatorChanges);
        finalized = FinalizedBlock(h, block.number, b.block);
    }
}
