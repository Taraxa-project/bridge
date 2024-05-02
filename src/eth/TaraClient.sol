// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../lib/Maths.sol";
import {HashesNotMatching, InvalidBlockInterval, ThresholdNotMet} from "../errors/ClientErrors.sol";
import "../lib/ILightClient.sol";
import "../lib/PillarBlock.sol";

contract TaraClient is IBridgeLightClient, OwnableUpgradeable {
    PillarBlock.FinalizedBlock public finalized;
    mapping(address => uint256) public validatorVoteCounts;
    uint256 public totalWeight;
    uint256 public threshold;
    uint256 public pillarBlockInterval;

    /// gap for upgrade safety <- can be used to add new storage variables(using up to 49  32 byte slots) in new versions of this contract
    /// If used, decrease the number of slots in the next contract that inherits this one(ex. uint256[48] __gap;)
    uint256[49] __gap;

    /// Events
    event Initialized(PillarBlock.FinalizedBlock finalized, uint256 threshold, uint256 pillarBlockInterval);
    event ThresholdChanged(uint256 threshold);
    event ValidatorWeightChanged(address indexed validator, uint256 weight);
    event BlockFinalized(PillarBlock.FinalizedBlock finalized);

    function initialize(PillarBlock.WithChanges memory _genesisBlock, uint256 _threshold, uint256 _pillarBlockInterval)
        public
        initializer
    {
        __TaraClient_init_unchained(_genesisBlock, _threshold, _pillarBlockInterval);
    }

    function __TaraClient_init_unchained(
        PillarBlock.WithChanges memory _genesisBlock,
        uint256 _threshold,
        uint256 _pillarBlockInterval
    ) internal onlyInitializing {
        __Ownable_init(msg.sender);
        finalized = PillarBlock.FinalizedBlock(PillarBlock.getHash(_genesisBlock), _genesisBlock.block, block.number);
        processValidatorChanges(_genesisBlock.validatorChanges);
        threshold = _threshold;
        pillarBlockInterval = _pillarBlockInterval;
        emit Initialized(finalized, threshold, pillarBlockInterval);
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
    function setThreshold(uint256 _threshold) public onlyOwner {
        threshold = _threshold;
        emit ThresholdChanged(threshold);
    }

    /**
     * @dev Processes the changes in validator weights.
     * @param validatorChanges An array of VoteCountChange structs representing the changes in validator vote counts.
     */
    function processValidatorChanges(PillarBlock.VoteCountChange[] memory validatorChanges) public {
        uint256 validatorChangesLength = validatorChanges.length;
        for (uint256 i = 0; i < validatorChangesLength;) {
            validatorVoteCounts[validatorChanges[i].validator] =
                Maths.add(validatorVoteCounts[validatorChanges[i].validator], validatorChanges[i].change);
            totalWeight = Maths.add(totalWeight, validatorChanges[i].change);
            emit ValidatorWeightChanged(
                validatorChanges[i].validator, validatorVoteCounts[validatorChanges[i].validator]
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Pinalizes blocks by verifying the signatures for the last blocks
     * @param blocks list of PillarBlockWithChanges.
     * @param lastBlockSigs An array of Signature structs representing the signatures of the last block.
     */
    function finalizeBlocks(PillarBlock.WithChanges[] memory blocks, CompactSignature[] memory lastBlockSigs) public {
        uint256 blocksLength = blocks.length;
        for (uint256 i = 0; i < blocksLength; i++) {
            bytes32 pbh = PillarBlock.getHash(blocks[i]);
            if (blocks[i].block.prevHash != finalized.blockHash) {
                revert HashesNotMatching({expected: finalized.blockHash, actual: blocks[i].block.prevHash});
            }
            if (blocks[i].block.period != (finalized.block.period + pillarBlockInterval)) {
                revert InvalidBlockInterval({
                    expected: finalized.block.period + pillarBlockInterval,
                    actual: blocks[i].block.period
                });
            }

            // this should be processed before the signatures verification to have a proper weights
            processValidatorChanges(blocks[i].validatorChanges);
            // verify signatures only for the last block
            if (i == (blocks.length - 1)) {
                uint256 weight =
                    getSignaturesWeight(PillarBlock.getVoteHash(blocks[i].block.period, pbh), lastBlockSigs);
                if (weight < threshold) {
                    revert ThresholdNotMet({threshold: threshold, weight: weight});
                }
            }
            finalized = PillarBlock.FinalizedBlock(pbh, blocks[i].block, block.number);
            emit BlockFinalized(finalized);
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
        uint256 signaturesLength = signatures.length;
        for (uint256 i = 0; i < signaturesLength; i++) {
            address signer = ECDSA.recover(h, signatures[i].r, signatures[i].vs);
            weight += validatorVoteCounts[signer];
        }
    }
}
