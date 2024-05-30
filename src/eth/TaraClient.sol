// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../lib/Maths.sol";
import {HashesNotMatching, InvalidBlockInterval, ThresholdNotMet} from "../errors/ClientErrors.sol";
import "../lib/IBridgeLightClient.sol";
import "../lib/PillarBlock.sol";

contract TaraClient is IBridgeLightClient, OwnableUpgradeable {
    /// Contains the last finalized block
    PillarBlock.FinalizedBlock public finalized;
    /// Contains the last finalized block for each epoch
    mapping(uint256 => bytes32) public finalizedBridgeRoots;
    mapping(address => uint256) public validatorVoteCounts;
    uint256 public totalWeight;
    uint256 public threshold;
    uint256 public pillarBlockInterval;

    /// gap for upgrade safety <- can be used to add new storage variables(using up to 49  32 byte slots) in new versions of this contract
    /// If used, decrease the number of slots in the next contract that inherits this one(ex. uint256[48] __gap;)
    uint256[49] __gap;

    /// Events
    event Initialized(uint256 threshold, uint256 pillarBlockInterval);
    event ThresholdChanged(uint256 threshold);
    event ValidatorWeightChanged(address indexed validator, uint256 weight);
    event BlockFinalized(PillarBlock.FinalizedBlock finalized);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _threshold, uint256 _pillarBlockInterval) public initializer {
        __TaraClient_init_unchained(_threshold, _pillarBlockInterval);
    }

    function __TaraClient_init_unchained(uint256 _threshold, uint256 _pillarBlockInterval) internal onlyInitializing {
        __Ownable_init(msg.sender);
        threshold = _threshold;
        pillarBlockInterval = _pillarBlockInterval;
        emit Initialized(threshold, pillarBlockInterval);
    }

    function getFinalized() public view returns (PillarBlock.FinalizedBlock memory) {
        return finalized;
    }

    /**
     * @dev Returns the finalized bridge root.
     * @return The finalized bridge root as a bytes32 value.
     */
    function getFinalizedBridgeRoot(uint256 epoch) external view returns (bytes32) {
        return finalizedBridgeRoots[epoch];
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
    function processValidatorChanges(PillarBlock.VoteCountChange[] memory validatorChanges) internal {
        uint256 validatorChangesLength = validatorChanges.length;
        for (uint256 i = 0; i < validatorChangesLength;) {
            require(validatorChanges[i].validator != address(0), "TaraClient: validator is the zero address");
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
        for (uint256 i = 0; i < blocksLength;) {
            bytes32 pbh = PillarBlock.getHash(blocks[i]);
            if (blocks[i].block.prevHash != finalized.blockHash) {
                revert HashesNotMatching({expected: finalized.blockHash, actual: blocks[i].block.prevHash});
            }
            if (finalized.block.period != 0 && blocks[i].block.period != (finalized.block.period + pillarBlockInterval))
            {
                revert InvalidBlockInterval({
                    expected: finalized.block.period + pillarBlockInterval,
                    actual: blocks[i].block.period
                });
            }

            // this should be processed before the signatures verification to have a proper weights
            processValidatorChanges(blocks[i].validatorChanges);
            // skip verification for the first(genesis) block. And verify signatures only for the last block in the batch
            if (finalized.block.period != 0 && i == (blocks.length - 1)) {
                uint256 weight =
                    getSignaturesWeight(PillarBlock.getVoteHash(blocks[i].block.period, pbh), lastBlockSigs);
                if (weight < threshold) {
                    revert ThresholdNotMet({threshold: threshold, weight: weight});
                }
            }
            finalizedBridgeRoots[blocks[i].block.period] = finalized.block.bridgeRoot;
            // add the last block to the single finalized block
            finalized = PillarBlock.FinalizedBlock(pbh, blocks[i].block, block.number);
            emit BlockFinalized(finalized);
            unchecked {
                ++i;
            }
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
